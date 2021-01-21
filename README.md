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
