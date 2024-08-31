FROM mcr.microsoft.com/dotnet/aspnet:8.0-jammy-chiseled

ARG artifactStagingPath

EXPOSE 80 443

COPY $artifactStagingPath .

ENTRYPOINT ["dotnet", "pong.dll"]