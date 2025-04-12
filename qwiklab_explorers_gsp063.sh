#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Your API key: ${RESET_FORMAT}" KEY
export KEY

# Enabling the required API
gcloud services enable language.googleapis.com

# Fetching the zone
ZONE="$(gcloud compute instances list --project=$DEVSHELL_PROJECT_ID --format='value(ZONE)')"

# Adding metadata to the instance
gcloud compute instances add-metadata linux-instance --metadata API_KEY="$KEY" --project=$DEVSHELL_PROJECT_ID --zone=$ZONE

# Creating the prepare_disk.sh script
cat > prepare_disk.sh <<'EOF_END'

API_KEY=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/API_KEY)

export API_KEY="$API_KEY"  # Export the API key to the script

cat > request.json <<EOF
{
    "document":{
      "type":"PLAIN_TEXT",
      "content":"A Smoky Lobster Salad With a Tapa Twist. This spin on the Spanish pulpo a la gallega skips the octopus, but keeps the sea salt, olive oil, pimentón and boiled potatoes."
    }
  }
EOF


curl "https://language.googleapis.com/v1/documents:classifyText?key=${API_KEY}" \
  -s -X POST -H "Content-Type: application/json" --data-binary @request.json

  curl "https://language.googleapis.com/v1/documents:classifyText?key=${API_KEY}" \
  -s -X POST -H "Content-Type: application/json" --data-binary @request.json > result.json

EOF_END

# Copying the script to the instance
gcloud compute scp prepare_disk.sh linux-instance:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

# Executing the script on the instance
gcloud compute ssh linux-instance --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="export API_KEY=$KEY && bash /tmp/prepare_disk.sh"

# Creating BigQuery dataset and table
bq --location=US mk --dataset $DEVSHELL_PROJECT_ID:news_classification_dataset

bq mk --table $DEVSHELL_PROJECT_ID:news_classification_dataset.article_data article_text:STRING,category:STRING,confidence:FLOAT

# Completion message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}    CONGRATULATIONS YOU COMPLETED THE LAB SUCCESSFULLY!       ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my YT Channel (QwikLab Explorers):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@qwiklabexplorers${RESET_FORMAT}"
