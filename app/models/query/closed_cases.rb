module Query
  class ClosedCases
    attr_reader :results, :limit, :offset

    def init(offset: nil, limit: nil)
      @offset = offset
      @limit = limit
    end

    def execute
      @results ||= ActiveRecord::Base.connection.exec_query(query)
    end

    def query
      limit = []
      limit << "LIMIT #{@limit}" if @limit.present?
      limit << "OFFSET #{@offset}" if @offset.present?

      <<-SQL
        SELECT
          -- 0. Case number
          c.number,

          -- 1. Case type
          c.type,

          -- 2. Case state
          c.current_state,

          -- 3. Responding Team
          (SELECT  "teams"."name" FROM "teams"
            INNER JOIN "assignments"
            ON "teams"."id" = "assignments"."team_id"
            WHERE "assignments"."case_id" = c.id
            AND "assignments"."role" = 'responding'
            AND ("assignments"."state" != 'rejected')
            ORDER BY "assignments"."id" DESC
            LIMIT 1 ) AS responding_team_name,

          -- 4. Responder
          (SELECT  "users"."full_name" FROM "users"
            INNER JOIN "assignments"
            ON "users"."id" = "assignments"."user_id"
            WHERE "assignments"."case_id" = c.id
            AND "assignments"."role" = 'responding'
            AND ("assignments"."state" != 'rejected')
            ORDER BY "assignments"."id" DESC
            LIMIT 1 ) AS responding_user_name,

          -- 5. Date received
          c.received_date,

          -- 6. Internal deadline
          c.properties->>'internal_deadline' AS internal_deadline,

          -- 7. External deadline
          c.properties->>'external_deadline' AS external_deadline,

          -- 8. Date responded
          c.date_responded,

          -- 9. Date compliant draft uploaded
          c.properties->>'date_draft_compliant',

          -- 10. Trigger
          (SELECT 1 FROM assignments a WHERE c.id = a.case_id AND a.role = 'approving' ORDER BY id  DESC limit 1 ) AS flagged,

          -- 11. Name
          c.name,

          -- 12. Requester type
          c.requester_type,

          -- 13. Message
          c.message,

          -- 14. Info held
          (SELECT cc.name FROM case_closure_metadata AS cc WHERE cc.id = c.info_held_status_id AND c.info_held_status_id <> NULL ORDER BY id  DESC limit 1) AS info_held_status,

          -- 15. Outcome
          (SELECT cc.name FROM case_closure_metadata AS cc WHERE cc.id = c.appeal_outcome_id AND c.appeal_outcome_id <> NULL ORDER BY id  DESC limit 1) AS outcome,

          -- 16. Refusal reason
          (SELECT cc.name FROM case_closure_metadata AS cc WHERE cc.id = c.refusal_reason_id AND c.refusal_reason_id <> NULL ORDER BY id  DESC limit 1) AS refusal_reason,

          -- 17. Exemptions
          (SELECT ARRAY(select m.abbreviation)
            FROM case_closure_metadata AS m
            INNER JOIN cases_exemptions AS e
            ON m.id = e.exemption_id
            WHERE m.type IN ('CaseClosure::Exemption')
            AND e.case_id = c.id
            ORDER BY m.sequence_id ASC) AS exemptions_map,

          -- 18. Postal address
          c.postal_address,

          -- 19. Email
          c.email,

          -- 20. Appeal outcome
          (SELECT cc.name FROM case_closure_metadata AS cc WHERE cc.id = c.appeal_outcome_id AND c.appeal_outcome_id <> NULL ORDER BY id  DESC limit 1) AS appeal_outcome,

          -- 21. Third party
          c.properties->>'third_party' AS third_party,

          -- 22. Reply method
          c.properties->>'reply_method' AS reply_method,

          -- 23. SAR Subject type
          c.properties->>'subject_type' AS subject_type,

          -- 24. SAR Subject full name
          c.properties->>'subject_full_name' AS subject_full_name,

          -- 25. Business unit responsible for late response
          (SELECT t.name FROM teams t WHERE t.id = NULLIF(c.properties->>'late_team_id', '')::int AND c.properties->>'late_team_id' <> NULL) AS late_team_name,

          -- 26. Extensions (SAR)
          (SELECT count(ct.event) FROM case_transitions ct WHERE ct.event = 'extend_deadline_for_sar' AND ct.case_id = c.id GROUP BY ct.event) AS num_sar_extensions,

          -- 27. Extension removals (SAR)
          (SELECT count(ct.event) FROM case_transitions ct WHERE ct.event = 'remove_extended_deadline_for_sar' AND ct.case_id = c.id  GROUP BY ct.event) AS num_sar_extension_removals,

          -- 28. Extensions (PIT)
          (SELECT count(ct.event) FROM case_transitions ct WHERE ct.event = 'extend_for_pit' AND ct.case_id = c.id  GROUP BY ct.event) AS num_pit_extensions,

          -- 29. Extension removals (PIT)
          (SELECT count(ct.event) FROM case_transitions ct WHERE ct.event = 'remove_extend_for_pit' AND ct.case_id = c.id  GROUP BY ct.event) AS num_sar_extension_removals,

          -- 30. Deletion reason
          c.reason_for_deletion,

          -- 31. Casework officer
          (SELECT u.full_name FROM users AS u
            inner join assignments a
            on a.user_id = u.id
            AND a.case_id = c.id
            AND a."role" = 'approving'
            AND a."state" = 'accepted' limit 1) AS caseworker,

          -- 32. Created by
          u.full_name AS created_by,

          -- 33. Date created
          c.created_at,

          -- 34. Business group
          NULL AS business_group_name,

          -- 35. Directorate name
          NULL AS directorate_name,

          -- 36. Director General name
          NULL AS director_general_name,

          -- 37. Director name
          NULL AS director_name,

          -- 38. Deputy Director name
          NULL AS deputy_director_name,

          -- 39. Draft in time
          c.properties->>'date_draft_compliant' AS date_draft_compliant,

          -- 40. In target
          NULL AS response_in_target,

          -- 41. Number of responses
          (SELECT count(ct.event) FROM case_transitions ct WHERE ct.case_id = c.id AND ct."event" = 'respond' GROUP BY ct.event) AS num_responded,

          -- 42. Number of days late
          (SELECT DATE_PART('day', now() - (c.properties->>'external_deadline')::timestamp)) AS num_days_late,

          -- 43. Workflow
          c.workflow

        FROM cases AS c
        LEFT JOIN Users u on u.id = c.user_id
        WHERE c.deleted = 'f'
        #{limit.join(' ')}
     SQL
    end
  end
end
