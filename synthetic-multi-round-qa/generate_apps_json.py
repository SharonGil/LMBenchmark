import json
import random
import string
import argparse

def random_string(length):
    """Generate a random string of fixed length."""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def generate_random_app(sys_prompt_len, tools_len, rag_doc_len, rag_doc_count):
    """Generate a random App object."""
    return {
        "systemPrompt": random_string(sys_prompt_len),
        "tools": random_string(tools_len),
        "ragDocs": [random_string(rag_doc_len) for _ in range(rag_doc_count)]
    }

def generate_apps_json(num_apps, sys_prompt_len, tools_len, rag_doc_len, rag_doc_count, output_file):
    """Generate a JSON array of random Apps."""
    apps = [generate_random_app(sys_prompt_len, tools_len, rag_doc_len, rag_doc_count) for _ in range(num_apps)]
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(apps, f, indent=4)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate random Apps JSON file")
    parser.add_argument("--num-apps", type=int, default=5, help="Number of apps to generate")
    parser.add_argument("--sys-prompt-len", type=int, default=5000, help="Length of system prompt strings")
    parser.add_argument("--tools-len", type=int, default=200, help="Length of tools strings")
    parser.add_argument("--rag-doc-len", type=int, default=1000, help="Length of each RAG document")
    parser.add_argument("--rag-doc-count", type=int, default=10, help="Number of RAG documents per app")
    parser.add_argument("--output", type=str, default="Apps.json", help="Output filename")
    
    args = parser.parse_args()
    
    generate_apps_json(
        args.num_apps,
        args.sys_prompt_len,
        args.tools_len,
        args.rag_doc_len,
        args.rag_doc_count,
        args.output
    ) 