h1. Spec Steps

The files in these subdirs define re-usable steps designed to be used in the
feature and end-to-end tests. The thinking is that while tests shouldn't be DRY,
sometimes it's clearer to have well-named steps that are being performed in
tests and with parameters that clearly describe what is being done and the
expected outcome.

h2. Actions

These steps are coarser-grained than Cucumber steps, and closer to how specs
behave in that they contain both an action and expectations of the results of
the actions within the steps. The name of the step describes the action being
taken (e.g. `request_amends``, or `approve_response`) and generally should focus
on a single action taken on one of the system's pages (e.g. by clicking the
"request amends" button on the case details page).

h2. Expectations

After performing an action a step will check certain expectations to demonstrate
that the action has been taken and that the system is in an expected state. As
these steps are meant to accomodate many use cases, expected values should be
parameterised with names that begin with 'expected_' (e.g. `expected_team`)

h2. Parameterisation

As these steps are meant to be reusable, key values for the action and expected
results are parameterised in such a way as to make it clear in the spec that's
using the step what is being done and what is expected to occur.


