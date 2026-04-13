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
#         ]
#     }'


curl http://localhost:9000/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{
        "model": "Qwen/Qwen3.5-27B",
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "Describe this video."},
                    {
                        "type": "video_url",
                        "video_url": {"url": "file:///home/emarrese/space_woaudio.mp4"},
                        "fps": 10
                    }
                ]
            }
        ],
        "mm_processor_kwargs": {        
            "size": {
                "shortest_edge": 4096,
                "longest_edge": 10240000
            }
        }
    }'




# curl http://localhost:9000/v1/chat/completions \
#     -H "Content-Type: application/json" \
#     -d '{
#         "model": "Qwen/Qwen3.5-27B",
#         "messages": [
#             {
#                 "role": "user",
#                 "content": [
#                 {"type": "text", "text": "Describe this video."},
#                 {
#                     "type": "video_url",
#                     "video_url": {"url": "file:///home/emarrese/space_woaudio.mp4"}
#                 }
#             ]
#         ],
#         "temperature": 0.7,
#         "mm_processor_kwargs": {
#         "video": {
#             "fps": 1.0,
#         },
#         "size": {
#             "shortest_edge": 768,
#             "longest_edge": 1024
#         }
#         }
#   }'



# curl http://localhost:9000/v1/chat/version 
