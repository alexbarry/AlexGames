# NOTE: you must build the image `alexgames_http_server` first,
#       without specifying a target like the command in README.md.
#
# Run this command:
#     sudo docker build -t alexgames_http_server \
#         -f docker/http_server/Dockerfile \
#         .
#
#
# Then to build this image and get its contents, run this command:
#     sudo docker build -t alexgames_electron \
#         -f docker/electron/Dockerfile \
#         --target=alexgames_dist_electron \
#         --output=build/electron/out/ \
#         .

FROM alexgames_http_server as alexgames_build_electron


RUN apt-get update && apt-get install -y \
	nodejs \
	npm \
	rpm


WORKDIR /app/build/electron

RUN npm run build
RUN npm run make

FROM scratch as alexgames_dist_electron
COPY --from=alexgames_build_electron /app/build/electron/out/* /
