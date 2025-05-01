# pre-commit

Image to be used as a CI linting step in infrastructure repositories

[Learn more](https://pre-commit.com/) about the framework

### Example of Use

<details>
  <summary>Gitlab</summary>

#### .gitlab-ci.yml

  ```yaml
  stages:
    - &lint "🧹 LINT"

  pre-commit:
    stage: *lint
    image: ghcr.io/mayconritzmann/pre-commit:v1.0.0
    before_script:
      - . /etc/profile.d/asdf.sh
      - '[ -f .tool-versions ] && /installer/add-tools.sh .tool-versions || true'
      - git config --global --add safe.directory $CI_PROJECT_DIR
    script:
      - pre-commit run --all-files --verbose --color always
    only:
      - merge_requests
  ```

</details>
