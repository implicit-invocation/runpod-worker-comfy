# Use Nvidia CUDA base image
FROM renderer/comfy-runpod-docker:1.0.0 as base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1

WORKDIR /comfyui
# Download checkpoints/vae/LoRA to include in image
# RUN wget -O models/checkpoints/sd_xl_base_1.0.safetensors https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
# RUN wget -O models/vae/sdxl_vae.safetensors https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors
# RUN wget -O models/vae/sdxl-vae-fp16-fix.safetensors https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/sdxl_vae.safetensors
# RUN wget -O models/loras/xl_more_art-full_v1.safetensors https://civitai.com/api/download/models/152309
RUN --mount=type=secret,id=CIVITAI_TOKEN \
    wget -O models/checkpoints/pixelmix_v20.safetensors https://civitai.com/api/download/models/339641?token=$(cat /run/secrets/CIVITAI_TOKEN)
RUN --mount=type=secret,id=CIVITAI_TOKEN \
    wget -O models/loras/Ghibli_v6.safetensors https://civitai.com/api/download/models/125985?token=$(cat /run/secrets/CIVITAI_TOKEN)

WORKDIR /comfyui/custom_nodes
RUN git clone https://github.com/Jcd1230/rembg-comfyui-node.git
RUN cd rembg-comfyui-node && pip3 install -r requirements.txt && cd ..

RUN mkdir -p /root/.u2net
RUN wget -O /root/.u2net/u2net.onnx https://github.com/danielgatis/rembg/releases/download/v0.0.0/u2net.onnx
RUN pip3 install rembg[gpu]

# Go back to the root
WORKDIR /

# Add the start and the handler
ADD src/start.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh

# Start the container
CMD /start.sh
