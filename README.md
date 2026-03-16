# IoT Hub Platform

Platform-level repository for production-like deployment and infrastructure orchestration of the IoT Hub microservices system.

## Purpose

The `iot-hub-platform` repository is responsible for assembling independently built microservices into a single runnable platform environment.

It does not contain business logic of individual services.  
Instead, it defines how production-like environments are composed, configured, and operated.

## Responsibilities

- define platform-level orchestration for all microservices
- run shared infrastructure components such as Kafka, PostgreSQL, Redis, NGINX, and monitoring tools
- pull and run published service container images
- provide environment wiring between services
- define production-like deployment structure
- support end-to-end platform startup and smoke validation

## Scope

This repository is the integration point for the distributed system as a whole.

It contains:
- Docker Compose files or equivalent orchestration manifests
- infrastructure configuration
- shared environment templates
- monitoring and routing configuration
- platform-level operational scripts
- deployment documentation
