#!/bin/bash
set -e

## Constants
GITHUB_TOKEN="$1"
XS_LIMIT="$2"
SM_LIMIT="$3"
MD_LIMIT="$4"
LG_LIMIT="$5"
URI="https://api.github.com"
API_HEADER="Accept: application/vnd.github.v3.json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"
XS_COLOR="00FF3A"
SM_COLOR="9CFF00"
MD_COLOR="EFFF00"
LG_COLOR="FF7500"
XL_COLOR="C60404"
LABEL_XS="${custom_tag_xs}"
LABEL_SM="${custom_tag_sm}"
LABEL_MD="${custom_tag_md}"
LABEL_LG="${custom_tag_lg}"
LABEL_XL="${custom_tag_xl}"

if [ -z "$GITHUB_REPOSITORY" ]; then
  echo "[ERROR] The env variable GITHUB_REPOSITORY is required"
  exit 1
fi

if [ -z "$GITHUB_EVENT_PATH" ]; then
  echo "[ERROR] The env variable GITHUB_EVENT_PATH is required"
  exit 1
fi

echo "[INFO] Github Event"
echo "$GITHUB_EVENT_PATH"

number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")

# Add a label to an issue
# it returns an array of labels
add_label() {
  echo "$(curl -sSL -H "$AUTH_HEADER" -H "$API_HEADER" -X POST -H "Content-Type: application/json" -d \
    "{\"labels\": [\"$1\"]}" "${URI}/repos/${GITHUB_REPOSITORY}/issues/$number/labels")"
}

delete_label() {
  curl -sSL -H "$AUTH_HEADER" -H "$API_HEADER" -X DELETE -H "Content-Type: application/json" \
    "${URI}/repos/${GITHUB_REPOSITORY}/issues/$number/labels/$1"
}

update_label_color() {
  #https://developer.github.com/v3/issues/labels/#get-a-label
  curl -sSL -H "$AUTH_HEADER" -H "$API_HEADER" -X PATCH -H "Content-Type: application/json" -d \
    "{\"color\": \"$2\"}" "${URI}/repos/${GITHUB_REPOSITORY}/labels/$1"
}

label_for() {
  if [ "$1" -lt "$XS_LIMIT" ]; then
    label="$LABEL_XS"
  elif [ "$1" -lt "$SM_LIMIT" ]; then
    label="$LABEL_SM"
  elif [ "$1" -lt "$MD_LIMIT" ]; then
    label="$LABEL_MD"
  elif [ "$1" -lt "$LG_LIMIT" ]; then
    label="$LABEL_LG"
  else
    label="$LABEL_XL"
  fi

  echo "$label"
}

get_label_color() {
  if [ "$1" = "$LABEL_XS" ]; then
    color="$XS_COLOR"
  elif [ "$1" = "$LABEL_SM" ]; then
    color="$SM_COLOR"
  elif [ "$1" = "$LABEL_MD" ]; then
    color="$MD_COLOR"
  elif [ "$1" = "$LABEL_LG" ]; then
    color="$LG_COLOR"
  else
    color="$XL_COLOR"
  fi
  echo "$color"
}

check_for_existing() {
  label=""
  if [ "$1" = "$LABEL_XS" ]; then
    label=$1
  elif [ "$1" = "$LABEL_SM" ]; then
    label="$1"
  elif [ "$1" = "$LABEL_MD" ]; then
    label="$1"
  elif [ "$1" = "$LABEL_LG" ]; then
    label="$1"
  elif [ "$1" = "$LABEL_XL" ]; then
    label="$1"
  fi

  if [ -n "$label" ]; then
    echo "[INFO] Removing label $label"
    delete_label "$label"
  fi
}

autolabel() {
  #https://developer.github.com/v3/pulls/#get-a-pull-request
  body=$(curl -sSL -H "${AUTH_HEADER}" -H "${API_HEADER}" "${URI}/repos/${GITHUB_REPOSITORY}/pulls/${number}")
  additions=$(echo "$body" | jq '.additions')
  deletions=$(echo "$body" | jq '.deletions')
  total_modifications=$(echo "$additions + $deletions" | bc)
  label_to_add=$(label_for "$total_modifications")

  # Check if pr has been labeled already
  labels=$(echo "$body" | jq -r '.labels[] | @base64')
  existing_label=""

  for label in "${labels[@]}"; do
    _parse() {
      echo "$label" | base64 --decode | jq -r "$1"
    }

    label_name=$(_parse '.name')

    if [ "$label_name" = "$label_to_add" ]; then
      # Already labeled
      existing_label="$label"
    else
      check_for_existing "$label_name"
    fi
  done

  if [ -n "$existing_label" ]; then
    # The label already exists encoded
    label_existing_color=$(echo "$existing_label" | base64 --decode | jq -r '.color')
    echo "[INFO] Label existing color $label_existing_color"
    label_color=$(get_label_color "$label_to_add")
    if [ "$label_existing_color" != "$label_color" ]; then
      echo "[INFO] Updating existing label $label_to_add color..."
      update_label_color "$label_to_add" "$label_color"
    fi
  else
    echo "[INFO] Labelling pull request with $label_to_add"
    new_labels=$(add_label "$label_to_add" | jq -r '.[] | @base64')
    if [ -z "$new_labels" ]; then
      echo "[ERROR] new labels wrong parsed"
      exit 1
    fi
    # Check if the label color is correct
    for label in "${new_labels[@]}"; do
      _parse() {
        echo "$label" | base64 --decode | jq -r "$1"
      }
      label_name=$(_parse '.name')
      if [ "$label_name" = "$label_to_add" ]; then
        label_color=$(get_label_color "$label_name")
        label_current_color=$(_parse '.color')
        echo "[INFO] Label $label_name current color: $label_current_color"
        if [ "$label_current_color" != "$label_color" ]; then
          echo "[INFO] Updating new label $label_name color..."
          update_label_color "$label_name" "$label_color"
        fi
        break
      fi
    done
  fi
}

autolabel
