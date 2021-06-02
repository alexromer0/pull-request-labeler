# Pull request size labeler 📏
Github action to measure and level the size of pull request, this could be util for follow team conventions when we all agree on to not open pull request with more than X number of modifications.

ℹ️ The modifications are calculated based on the number of additions + number of deletions

## Configuration
The pull request sizes are configurable, currently it allows 4 sizes:
- XS extra small
- SM small
- MD medium
- LG large
- XL extra large

In your `workflows` folder create a worflow file e.g. `labeler.yml` and inside this file add this:
```yml
name: Labeler

on: [pull_request]

jobs:
  size-labeler:
    runs-on: ubuntu-latest
    name: 'Label the PR'
    steps:
      - name: Pull request size labelling
        uses: alexromer0/pull-request-labeler@2.1.1
        with:
          GITHUB_TOKEN: ${{secrets.GITHUB_TOKEN}}
          xs_limit: '50'
          sm_limit: '100'
          md_limit: '300'
          lg_limit: '600'
```

Feel free to adjust the size limits to your needs


## Dealing with dependabot 
If you have enable dependabot in your repo it might be that the "basic" configuration for this action fail 
whenever dependabot creates a pull request. This might be related to the fact that when dependabot creates a PR it does as read only
more info [here](https://github.blog/changelog/2021-02-19-github-actions-workflows-triggered-by-dependabot-prs-will-run-with-read-only-permissions/).
Anyways the suggested solution is to change the event type in your action file and use `pull_request_target` so your action file should look like this
```yml
name: Labeler

on: [pull_request_target]

jobs:
  size-labeler:
    runs-on: ubuntu-latest
    name: 'Label the PR'
    steps:
      - name: Pull request size labelling
        uses: alexromer0/pull-request-labeler@2.1.1
        with:
          GITHUB_TOKEN: ${{secrets.GITHUB_TOKEN}}
          xs_limit: '50'
          sm_limit: '100'
          md_limit: '300'
          lg_limit: '600'
```
