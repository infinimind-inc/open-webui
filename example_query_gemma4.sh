
# curl http://localhost:9000/v1/chat/completions \
#     -H "Content-Type: application/json" \
#     -d '{
#         "model": "Qwen/Qwen3.5-27B",
#         "messages": [
#             {
#                 "role": "user",
#                 "content": [
#                     {"type": "text", "text": "Describe this video."},
#                     {
#                         "type": "video_url",
#                         "video_url": {"url": "file:///home/emarrese/space_woaudio.mp4"},
#                         "fps": 10
#                     }
#                 ]
#             }
#         ],
#         "mm_processor_kwargs": {        
#             "max_soft_tokens": 560
#         }
#     }'



curl http://localhost:9999/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{
        "model": "nvidia/Gemma-4-31B-IT-NVFP4",
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "What is the meaning of life?."}
                ]
            }
        ]
    }'
