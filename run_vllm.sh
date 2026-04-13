
# source $HOME/miniconda3/bin/activate transformers

vllm serve Qwen/Qwen3.5-27B \
    --port 9000 \
    --host 0.0.0.0 \
    --reasoning-parser qwen3 \
    --kv-cache-dtype fp8 \
    --gpu-memory-utilization 0.6 \
    --allowed-local-media-path / \
    --limit-mm-per-prompt '{"video": {"count": 1}}' \
    --enable-auto-tool-choice \
    --tool-call-parser qwen3_coder \
    --max-model-len 65536 \
    --quantization bitsandbytes \
    --trust-remote-code \
    --dtype bfloat16 \
    --max-num-seqs 1

# CUDA_VISIBLE_DEVICES=0 docker run \
# --runtime nvidia \
# --gpus all \
# --network=host \
# -v ~/.cache/huggingface:/root/.cache/huggingface \
# vllm/vllm-openai Qwen/Qwen3.5-27B \
# --port 9000 \
# --host 0.0.0.0 \
# --reasoning-parser qwen3 \
# --enable-prefix-caching \
# --mm-encoder-tp-mode data \
# --mm-processor-cache-type shm \
# --reasoning-parser qwen3 \
# --enable-prefix-caching \
# --enable-auto-tool-choice \
# --tool-call-parser qwen3_coder \
# --gpu-memory-utilization 0.9 \
# --max-model-len 262144 \
# --trust-remote-code \
# --dtype bfloat16 \
# --disable-log-requests \
# --max-num-seqs ${MAX_NUM_SEQS} \
# --media-io-kwargs '{"video": {"fps": 2, "num_frames": 2048}}' \
# --mm-processor-kwargs '{"size": {"shortest_edge": 262144, "longest_edge": 234881024}}'
