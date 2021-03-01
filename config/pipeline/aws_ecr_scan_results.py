import boto3
import argparse
import requests
import json
import os


class ECRScanChecker:
    aws_account_id = ''
    aws_iam_session = ''
    aws_ecr_client = ''
    images_to_check = []
    tag = ''
    report = ''
    report_limit = ''

    def __init__(self, report_limit, search_term):
        self.report_limit = int(report_limit)
        self.aws_ecr_client = boto3.client(
            'ecr',
            region_name='eu-west-2',
            aws_access_key_id=self.aws_iam_session['Credentials']['AccessKeyId'],
            aws_secret_access_key=self.aws_iam_session['Credentials']['SecretAccessKey'],
            aws_session_token=self.aws_iam_session['Credentials']['SessionToken'])
        self.images_to_check = self.get_repositories(search_term)


    def get_repositories(self, search_term):
        images_to_check = []
        response = self.aws_ecr_client.describe_repositories()
        for repository in response["repositories"]:
            if search_term in repository["repositoryName"]:
                images_to_check.append(repository["repositoryName"])
        return images_to_check

    def recursive_wait(self, tag):
        print("Waiting for ECR scans to complete...")
        for image in self.images_to_check:
            self.wait_for_scan_completion(image, tag)
        print("ECR image scans complete")

    def wait_for_scan_completion(self, image, tag):
        try:
            waiter = self.aws_ecr_client.get_waiter('image_scan_complete')
            waiter.wait(
                repositoryName=image,
                imageId={
                    'imageTag': tag
                },
                WaiterConfig={
                    'Delay': 5,
                    'MaxAttempts': 60
                }
            )
        except:
            print("No ECR image scan results for image {0}, tag {1}".format(
                image, tag))

    def recursive_check_make_report(self, tag):
        print("Checking ECR scan results...")
        for image in self.images_to_check:
            try:
                findings = self.get_ecr_scan_findings(image, tag)[
                    "imageScanFindings"]
                if findings["findings"] != []:

                    counts = findings["findingSeverityCounts"]
                    title = "\n\n:warning: *AWS ECR Scan found results for {}:* \n".format(
                        image)
                    severity_counts = "Severity finding counts:\n{}\nDisplaying the first {} in order of severity\n\n".format(
                        counts, self.report_limit)
                    self.report = title + severity_counts

                    for finding in findings["findings"]:
                        cve = finding["name"]
                        severity = finding["severity"]

                        description = "None"
                        if "description" in finding:
                            description = finding["description"]

                        link = finding["uri"]
                        result = "*Image:* {0} \n**Tag:* {1} \n*Severity:* {2} \n*CVE:* {3} \n*Description:* {4} \n*Link:* {5}\n\n".format(
                            image, tag, severity, cve, description, link)
                        self.report += result
                    print(self.report)
            except:
                print("Unable to get ECR image scan results for image {0}, tag {1}".format(
                    image, tag))

    def get_ecr_scan_findings(self, image, tag):
        response = self.aws_ecr_client.describe_image_scan_findings(
            repositoryName=image,
            imageId={
                'imageTag': tag
            },
            maxResults=self.report_limit
        )
        return response

    def post_to_slack(self, slack_webhook):
        if self.report != "":
            branch_info = "*Github Branch:* {0}\n*CircleCI Job Link:* {1}\n\n".format(
                os.getenv('CIRCLE_BRANCH', ""),
                os.getenv('CIRCLE_BUILD_URL', ""))
            self.report += branch_info
            print(self.report)

            post_data = json.dumps({"text": self.report})
            response = requests.post(
                slack_webhook, data=post_data,
                headers={'Content-Type': 'application/json'}
            )
            if response.status_code != 200:
                raise ValueError(
                    'Request to slack returned an error %s, the response is:\n%s'
                    % (response.status_code, response.text)
                )


def main():
    parser = argparse.ArgumentParser(
        description="Check ECR Scan results for all service container images.")
    parser.add_argument("--search",
                        default="",
                        help="The root part oof the ECR repositry path, for example online-lpa")
    parser.add_argument("--tag",
                        default="latest",
                        help="Image tag to check scan results for.")
    parser.add_argument("--result_limit",
                        default=5,
                        help="How many results for each image to return. Defaults to 5")
    parser.add_argument("--slack_webhook",
                        default=os.getenv('SLACK_WEBHOOK'),
                        help="Webhook to use, determines what channel to post to")
    parser.add_argument("--post_to_slack",
                        default=True,
                        help="Optionally turn off posting messages to slack")

    args = parser.parse_args()
    work = ECRScanChecker(args.result_limit, args.search)
    work.recursive_wait(args.tag)
    work.recursive_check_make_report(args.tag)
    if args.slack_webhook is None:
        print("No slack webhook provided, skipping post of results to slack")
    if args.post_to_slack == True and args.slack_webhook is not None:
        work.post_to_slack(args.slack_webhook)


if __name__ == "__main__":
    main()
