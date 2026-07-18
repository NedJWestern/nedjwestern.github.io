###################
# Base stage
FROM docker.io/library/alpine:latest as base

RUN echo Base stage


###################
# QA stage
FROM base AS qa

RUN echo QA stage


###################
# Production stage
FROM base AS prod

RUN echo Production stage
