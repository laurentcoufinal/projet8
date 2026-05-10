FROM gradle:8.10.2-jdk21 AS build

WORKDIR /workspace
COPY java/G-rez-l-int-gration-et-la-livraison-continue-Application-Java/ ./
RUN chmod +x ./gradlew && ./gradlew clean bootJar -x test

FROM eclipse-temurin:21-jre

WORKDIR /app
COPY --from=build /workspace/build/libs/*.jar /app/app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
