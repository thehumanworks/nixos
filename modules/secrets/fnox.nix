{
  config,
  osConfig,
  pkgs,
  ...
}:

let
  host =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "mac"
    else if osConfig.wsl.enable or false then
      "wsl"
    else
      "linux";
in
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "fnix";
      runtimeInputs = [ config.programs.fnox.package ];
      text = ''
        export FNIX_HOST=${host}
        exec ${pkgs.python3}/bin/python3 -I ${./fnix.py} "$@"
      '';
    })
  ];

  programs.fnox = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    # Keep this block literal TOML: fnix lets fnox edit it in the checkout.
    settings = builtins.fromTOML ''
      # BEGIN fnix
      default_provider = "age"
      if_missing = "warn"

      [providers.age]
      type = "age"
      recipients = ["age1pvx764y47hjzlq0mp65f0zf2elvmcn3jckhttya9x34dz9c22eqqrev9vc"]

      [secrets]
      EXA_API_KEY = { provider = "age", value = "YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBCNjVkR3RkZVB1VkxjaHFod0xmdTVqeFgzKzlWcE54bGpubk5xd09INHpZClNORm1HL2JYR0NGQnZHZWQrQUpzZHFmTUx0R1FIMGZUWXpsZFdNWkQ4c00KLT4gKWhMUCdKOy1ncmVhc2UgZEJsfmpDLV4gVk5UW1IzMCAiVXhwRGMgWCJJClAwelZtU3JGQTZhcWZFOVYxbGt4YUtTbWFRUWNUcWhOd3p6bUpoZ2FnajhQTDRhdVlSVGFOc0hSS2xKMVVxSUEKRkNabWZLYUVnWUZlU2JkUzZRWTdxaFp3WnpqNlJRCi0tLSBBOTZ0dHM4cVVmWVk1NVFHSVpOQXFVOVpJRzlSUzVnNjJDdVZZalF6bFk0Co3vKOkCan69bbVNrpRzbIU8L3jSUQIMpJG/TXu/jPRFvTPqI/ulHmvccCVS/7aaqde0AW8zfj3rGf+Jt/dMKqk9F3VO" }
      CLAUDE_CODE_OAUTH_TOKEN = { provider = "age", value = "YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBlRDRlVHAzS0Q5cmdGcE9pazA2ZS9TenNpa0JTeGl1a3RBSnBsTW9qbVZJCnQwaTRXWUVhSkVRaFZQaU9jWFVyQUhFL3N6NFNLNmJYZjBSWUZneTA3ZU0KLT4gYFNiXj9KLWdyZWFzZSAiZ3o3RCc7TiA8IGpoPQo5U2VNSW5vc3hMcm0raFhnWlg5TDQ3WHg3VktYekF1dDgyUnhVUk54Ci0tLSBGSlQ0a2Mya0ZZdG1XemhxWk81RWFuVFNvOWRSZGJTRGF4cEtjYlpHWlBzCt06fKcyGn0KNpxW6RP7jq3mBGOJHqUC1UD1slEcLZrrcMj1g6BEP2hs53x2Cr1jiWxj0h3QujxuHrq+OlS8fzS4G5CmVsDJKlMN++F85JVzqXBcdtvtQd8ND4BtYdtt3+Btj/kqZ+DDFDmG2QCyptwOnd76k8rTeGr6HxUmzMNxzDdtMFUAShpYUNao" }
      CACHIX_AUTH_TOKEN = { provider = "age", value = "YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBwK0MxVTNzVDNkVDZWVzJQNUVFZmdSTXR6Szg1aG9qTEtrTmo0bm5abkZzCmMvVTZHZmEyd2NGVVR4RFh4MGdCTjVTdUZZTlZFT0ZhR2xrRDNCZ1RTK2cKLT4gUlVaLWdyZWFzZSBwKyBtTAorclFVRUppTAotLS0gVXU2U21Ob2VGVmx1VVJWdUNGK1c4emR5QkgxeVl6eDNYc0NPb2xvSjFZTQpuIsluxI9cCuFhU43/uoe/X8H25Bh5M8O1WdFKcsvNmCxI68ad9sELvpeangdtQZiw+Sm3cxsWNexBjB+hzS9Ryifqxe39Z3ZTPPvADPp1ZOGuKvYhedKXFcHFCYfUjphJAFL8Ut9Iy3iWnz94y6UYg+OpdpjFBow1jjMEdRHygtIt0KmPPMdQ8tx9gyPvfYu4gvl/5KgTrGcbznTMUmmDGBu1OgfNZ8VX48EvYyrQU0s=" }
      GITHUB_HOST = { provider = "age", value = "YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSB0QVBldVpDTk5yTVJYdUZ6T3JhbnFndEI4amFjZk9kZlA4RVFzZUsxOEE4CnYvRWNDVEhlSGpTQXVPUDJld0dsSzhxMlFNeEdIMSttZDRXcDV3cWlpaXcKLT4gVy1ncmVhc2UgfSkgNSBEW0JtaSVHICdNCm5GRnc2L1pIaVlUaUcvdW56YXRqdncKLS0tIHV0aDdhNzVlMEVTZDZrZ0sxdE9ua3lwWXFEVHFnUktLVmtGc1JUeHlTRUUKfZcOxellYTbmxWq8YAhkTAN017f3y4E1B/Pfp0WQaBAjG3H3xAx1DLT+" }
      GITHUB_ENTERPRISE_HOST = { provider = "age", value = "YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBkL2pJTWJIU2JYM2JPZys2WTdZU3RXQkdkanJNbnRnUXBrMW9nZDgvWENzCnFuNUJHaVBiaEQ2bVM2NVZHc0krZzNmenlEVDRXVUU2d2UzUWhXWGVxdTgKLT4gQT9PUGBZLWdyZWFzZQprVHo4dXRWL0RpV2JBemRPSC8wTWg2eVFzbGFpWlJDbjhKakJMOW5tSzQ0a3VzcXpwdThzc25sUGVneU5DaHRSCjE3cEtFdEN5U3JKb2V3Ci0tLSB1T0xBTlZsaUYxVTVOUEdZZjBHcHpiL1o5S2E3cElGOGVlZ0FsakloT080Cl5mVFY1RJ8l+lFl1/kNwVaUd6WgtrdUMrVdAKyrJWdnQ3ej2Y577A3iIuerxiBAg8BtzK/E" }
      GITHUB_ENTERPRISE_TOKEN = { provider = "age", value = "YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBYV2N3TFdKWUlKREx5WmlJOTJMS3dHemFSb0N4TU5MTkNrLy90WFF2Q1JVCnFGV01aUjdWdlRYKzJkK3M5cmdZOXR4VVhSNEpSYzFPbDltbVRkTHpXSWcKLT4gXW9DLWdyZWFzZQpEWVlNTmpjLzNVdjRUK1JLSXplOFhINTM4Q0k5VG9VaVhMQWNUcFhsblRoZjIvaGF5TmxlT1NMd1VXeHBCbTRXCjN2akVVOHFwaUNVdEZ1RkQ4ZGt3U1AyUUdOSFRmK1VvMTcwMUNzRmx5ZEpUa2ROQi9hT2RnUEEKLS0tIEY1MGlGa3d3SUxTSXB5NVluWGtDYW51RWZvTm8vSEhYNUV0OWZNc0V5b0UKQ+vKhPEcjJRAi7V6NuRAH6Nm39mNHUmEXS2df3WwTk5BrzxcW+QscqLISEq3YcJsF7muV2a/HaGuccFZhnCywA7h+Pydi4A/" }
      GITHUB_TOKEN = { provider = "age", value = "YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBjZlBYdzdsS3lZK3VDbTQvZkZKeWdNZTA5a2UxMXVPQnlxS2plZnFYenpBClQ5VEt3dS9IMG9Lay9BNGxMcWhVK3pVeFBmVEtYMldPQzQ4OGI5VFRCRncKLT4gLjctZ3JlYXNlIGc2K3M6UyBzIGB4fCAwd1E4CjQ4VnZOVzR5cVI0WVVyRDg0RzNXbURXWjFnZmNNSlhTNGFxY0JvUzUxanVnVEkwemVZeGdWdWc2a1hzNDhmUm0KUFpXMUkrc0RCSFhPQ1lHSi95K1BnWHVncGxiRTB0V1RSVTBVS1lzT1hNSQotLS0gUCtJMmJ1Snl3dWhVWkYvdERwbStyTno3L3Z4ZW5DSWFTekRocEhyMGFpWQo/CvTtgqin7b20cKWYrNZpFojc3YtSdEoWLN/hObAswErZ4zVatGUrewJCQXBqMKZ7Ev+QbjhOC+HQSa7CW6wltvyDwWeCcVs=" }
      # END fnix
    '';
  };
}
