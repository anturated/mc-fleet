{
  name = "casket";
  type = "cf";
  slug = "nightfallcraft-the-casket-of-reveries";
  zip = true;

  cfMods = ''
    chunky-pregenerator-forge
  '';
  cfExclude = ''
    chat-plus
    clear-water
    domestication-innovation-whitelist
    simple-bedrock-model
  '';

  docker.java = 17;
  server.motd = "Genshin Impact™";
}
