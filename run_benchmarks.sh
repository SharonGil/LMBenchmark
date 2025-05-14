#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Default values
MODEL=""
BASE_URL=""
KEY=""
SCENARIOS=("all")
QPS_VALUES=(1)
NUM_APPS="10"
USERS_PER_APP="2"
SYSTEM_PROMPT_LEN="1000"
RAG_DOC_LEN="200"
RAG_DOC_COUNT="5"
NUM_USERS="50"
NUM_ROUNDS="10"
DURATION="60"

# Parse named parameters
while [[ $# -gt 0 ]]; do
  case "$1" in
    --model=*)
      MODEL="${1#*=}"
      shift
      ;;
    --base_url=*)
      BASE_URL="${1#*=}"
      shift
      ;;
    --save_file_key=*)
      KEY="${1#*=}"
      shift
      ;;
    --scenarios=*)
      IFS=',' read -ra SCENARIOS <<< "${1#*=}"
      shift
      ;;
    --qps_values=*)
      IFS=',' read -ra QPS_VALUES <<< "${1#*=}"
      shift
      ;;
    --num_apps=*)
      NUM_APPS="${1#*=}"
      shift
      ;;
    --users_per_app=*)
      USERS_PER_APP="${1#*=}"
      shift
      ;;
    --system_prompt_len=*)
      SYSTEM_PROMPT_LEN="${1#*=}"
      shift
      ;;
    --rag_doc_len=*)
      RAG_DOC_LEN="${1#*=}"
      shift
      ;;
    --rag_doc_count=*)
      RAG_DOC_COUNT="${1#*=}"
      shift
      ;;
    --num_users=*)
      NUM_USERS="${1#*=}"
      shift
      ;;
    --num_rounds=*)
      NUM_ROUNDS="${1#*=}"
      shift
      ;;
    --duration=*)
      DURATION="${1#*=}"
      shift
      ;;
    # Backward compatibility for positional arguments
    *)
      if [[ -z "$MODEL" ]]; then
        MODEL="$1"
      elif [[ -z "$BASE_URL" ]]; then
        BASE_URL="$1"
      elif [[ -z "$KEY" ]]; then
        KEY="$1"
      elif [[ "$1" == "sharegpt" || "$1" == "short-input" || "$1" == "long-input" || "$1" == "long-long" || "$1" == "apps" || "$1" == "all" ]]; then
        SCENARIOS+=("$1")
      else
        QPS_VALUES+=("$1")
      fi
      shift
      ;;
  esac
done

# Check required parameters
if [[ -z "$MODEL" || -z "$BASE_URL" || -z "$KEY" ]]; then
    echo "Usage: $0 <model> <base url> <save file key> [scenarios...] [qps_values...]"
    echo "   or: $0 --model=\"model\" --base_url=\"url\" --save_file_key=\"key\" [--scenarios=\"scenario1,scenario2\"] [--qps_values=\"1.0,2.0\"]"
    echo ""
    echo "Scenarios:"
    echo "  sharegpt        - ShareGPT benchmark"
    echo "  short-input     - Short input, short output benchmark"
    echo "  long-input      - Long input, short output benchmark"
    echo "  long-long       - Long input, long output benchmark"
    echo "  all             - Run all benchmarks"
    echo ""
    echo "Examples:"
    echo "  # Run all benchmarks with default QPS"
    echo "  $0 meta-llama/Llama-3.1-8B-Instruct http://localhost:8000 /mnt/requests/benchmark all"
    echo ""
    echo "  # Run specific benchmarks with custom QPS"
    echo "  $0 meta-llama/Llama-3.1-8B-Instruct http://localhost:8000 /mnt/requests/benchmark sharegpt short-input 1.34 2.0 3.0"
    echo ""
    echo "  # Using named parameters"
    echo "  $0 --model=\"meta-llama/Llama-3.1-8B-Instruct\" --base_url=\"http://localhost:8000\" --save_file_key=\"/mnt/requests/benchmark\" --scenarios=\"sharegpt,short-input\" --qps_values=\"1.34,2.0,3.0\""
    exit 1
fi

# Print all parameters for logging
echo "============ BENCHMARK PARAMETERS ============"
echo "MODEL: $MODEL"
echo "BASE_URL: $BASE_URL"
echo "SAVE_FILE_KEY: $KEY"
echo "SCENARIOS: ${SCENARIOS[*]}"
echo "QPS_VALUES: ${QPS_VALUES[*]}"
echo "NUM_APPS: $NUM_APPS"
echo "USERS_PER_APP: $USERS_PER_APP"
echo "SYSTEM_PROMPT_LEN: $SYSTEM_PROMPT_LEN"
echo "RAG_DOC_LEN: $RAG_DOC_LEN"
echo "RAG_DOC_COUNT: $RAG_DOC_COUNT"
echo "NUM_USERS: $NUM_USERS"
echo "NUM_ROUNDS: $NUM_ROUNDS"
echo "DURATION: $DURATION"
echo "=============================================="

# Function to run ShareGPT benchmark
run_sharegpt() {
    echo "Running ShareGPT benchmark..."
    if [ ${#QPS_VALUES[@]} -eq 0 ]; then
        "${SCRIPT_DIR}/sharegpt/run.sh" "$MODEL" "$BASE_URL" "${KEY}_sharegpt"
    else
        "${SCRIPT_DIR}/sharegpt/run.sh" "$MODEL" "$BASE_URL" "${KEY}_sharegpt" "${QPS_VALUES[@]}"
    fi
}

# Function to run short input benchmark
run_short_input() {
    echo "Running short input benchmark..."
    if [ ${#QPS_VALUES[@]} -eq 0 ]; then
        "${SCRIPT_DIR}/synthetic-multi-round-qa/short_input_short_output.sh" "$MODEL" "$BASE_URL" "${KEY}_short_input"
    else
        "${SCRIPT_DIR}/synthetic-multi-round-qa/short_input_short_output.sh" "$MODEL" "$BASE_URL" "${KEY}_short_input" "${QPS_VALUES[@]}"
    fi
}

# Function to run long input benchmark
run_long_input() {
    echo "Running long input benchmark..."
    
    # Then run the actual benchmark
    if [ ${#QPS_VALUES[@]} -eq 0 ]; then
        "${SCRIPT_DIR}/synthetic-multi-round-qa/long_input_short_output_run.sh" "$MODEL" "$BASE_URL" "${KEY}_long_input"
    else
        "${SCRIPT_DIR}/synthetic-multi-round-qa/long_input_short_output_run.sh" "$MODEL" "$BASE_URL" "${KEY}_long_input" "${QPS_VALUES[@]}"
    fi
}

# Function to run long-long benchmark
run_long_long() {
    echo "Running long-long benchmark..."
    if [ ${#QPS_VALUES[@]} -eq 0 ]; then
        "${SCRIPT_DIR}/synthetic-multi-round-qa/long_input_long_output.sh" "$MODEL" "$BASE_URL" "${KEY}_long_long"
    else
        "${SCRIPT_DIR}/synthetic-multi-round-qa/long_input_long_output.sh" "$MODEL" "$BASE_URL" "${KEY}_long_long" "${QPS_VALUES[@]}"
    fi
}

# Function to run apps benchmark
run_apps() {
    echo "Running apps benchmark..."
    if [ ${#QPS_VALUES[@]} -eq 0 ]; then
        "${SCRIPT_DIR}/synthetic-multi-round-qa/app_input_short_output.sh" "$MODEL" "$BASE_URL" "${KEY}_apps" "$NUM_APPS" "$USERS_PER_APP" "$SYSTEM_PROMPT_LEN" "$RAG_DOC_LEN" "$RAG_DOC_COUNT" "$NUM_USERS" "$NUM_ROUNDS" "$DURATION"
    else
        "${SCRIPT_DIR}/synthetic-multi-round-qa/app_input_short_output.sh" "$MODEL" "$BASE_URL" "${KEY}_apps" "$NUM_APPS" "$USERS_PER_APP" "$SYSTEM_PROMPT_LEN" "$RAG_DOC_LEN" "$RAG_DOC_COUNT" "$NUM_USERS" "$NUM_ROUNDS" "$DURATION" "${QPS_VALUES[@]}"
    fi
}

# Run selected scenarios
for scenario in "${SCENARIOS[@]}"; do
    echo "Running scenario: $scenario"
    case "$scenario" in
        "sharegpt")
            run_sharegpt
            ;;
        "short-input")
            run_short_input
            ;;
        "long-input")
            run_long_input
            ;;
        "long-long")
            run_long_long
            ;;
        "apps")
            run_apps
            ;;
        "all")
            run_sharegpt
            run_short_input
            run_long_input
            ;;
    esac
done 
