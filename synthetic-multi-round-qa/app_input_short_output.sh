#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <model> <base url> <save file key> [num_apps users_per_app system_prompt_len rag_doc_len rag_doc_count num_users num_rounds duration qps_values...]"
    echo "Example: $0 meta-llama/Llama-3.1-8B-Instruct http://localhost:8000 test 1 4 100 1000 5 10 3 60 15 20 25"
    exit 1
fi

MODEL=$1
BASE_URL=$2
KEY=$3

# Configuration
NUM_USERS_WARMUP=100
CHAT_HISTORY=0
ANSWER_LEN=20

# Parse required parameters first
if [ $# -gt 3 ]; then
    NUM_APPS=$4
    USERS_PER_APP=$5
    SYSTEM_PROMPT_LEN=$6
    RAG_DOC_LEN=$7
    RAG_DOC_COUNT=$8
    NUM_USERS=$9
    NUM_ROUNDS=${10}
    DURATION=${11}
    
    # Get QPS values (all remaining arguments)
    if [ $# -gt 11 ]; then
        shift 11  # Skip the first 11 parameters
        QPS_VALUES=("$@")  # Capture all remaining arguments as QPS values
    else
        QPS_VALUES=(1)  # Default QPS value if none provided
    fi
else
    # Default values if only model, base URL, and key are provided
    NUM_APPS=1
    USERS_PER_APP=4
    SYSTEM_PROMPT_LEN=100
    RAG_DOC_LEN=1000
    RAG_DOC_COUNT=5
    NUM_USERS=10
    NUM_ROUNDS=3
    DURATION=60
    QPS_VALUES=(1)
fi

# init-user-id starts at 1, will add 400 each iteration
INIT_USER_ID=1

warmup() {
    echo "Warming up with QPS=$((NUM_USERS_WARMUP / 2))..."
    python3 "${SCRIPT_DIR}/multi-round-qa-apps.py" \
        --num-users 1 \
        --num-rounds 2 \
        --qps 2 \
        --shared-system-prompt "$(echo -n "$SYSTEM_PROMPT_LEN" | wc -w)" \
        --user-history-prompt "$(echo -n "$CHAT_HISTORY" | wc -w)" \
        --answer-len $ANSWER_LEN \
        --model "$MODEL" \
        --base-url "$BASE_URL" \
        --init-user-id "$INIT_USER_ID" \
        --output /tmp/warmup.csv \
        --log-interval 30 \
        --time 30 \
        --apps-file "${SCRIPT_DIR}/Apps.json" \
        --users-per-app 4
}

run_benchmark() {
    local qps=$1
    local output_file="${KEY}_qps${qps}.csv"

    python3 "${SCRIPT_DIR}/generate_apps_json.py"  --num-apps $NUM_APPS --sys-prompt-len $SYSTEM_PROMPT_LEN --rag-doc-len $RAG_DOC_LEN --rag-doc-count $RAG_DOC_COUNT --output "${SCRIPT_DIR}/Apps.json"
    # warmup with current init ID
    # warmup
    
    # actual benchmark with same init ID
    echo "Running benchmark with QPS=$qps..."
    python3 "${SCRIPT_DIR}/multi-round-qa-apps.py" \
        --num-users "$NUM_USERS" \
        --shared-system-prompt "$(echo -n "$SYSTEM_PROMPT_LEN" | wc -w)" \
        --user-history-prompt "$(echo -n "$CHAT_HISTORY" | wc -w)" \
        --answer-len "$ANSWER_LEN" \
        --num-rounds "$NUM_ROUNDS" \
        --qps "$qps" \
        --model "$MODEL" \
        --base-url "$BASE_URL" \
        --init-user-id "$INIT_USER_ID" \
        --output "$output_file" \
        --time "$DURATION" \
        --apps-file "${SCRIPT_DIR}/Apps.json" \
        --users-per-app "$USERS_PER_APP"
    
    sleep 10

    # increment init-user-id by NUM_USERS_WARMUP
    INIT_USER_ID=$(( INIT_USER_ID + NUM_USERS_WARMUP ))
}

# Run benchmarks for each QPS value
for qps in "${QPS_VALUES[@]}"; do
    run_benchmark "$qps"
done
