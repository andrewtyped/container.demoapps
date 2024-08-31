FROM mcr.microsoft.com/dotnet/aspnet:8.0-jammy-chiseled

EXPOSE 80 443

COPY ./bin/publish .

ENTRYPOINT ["dotnet", "ping.dll"]