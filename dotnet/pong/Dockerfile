FROM mcr.microsoft.com/dotnet/aspnet:8.0-jammy-chiseled

EXPOSE 80 443

COPY ./pong .

ENTRYPOINT ["dotnet", "pong.dll"]