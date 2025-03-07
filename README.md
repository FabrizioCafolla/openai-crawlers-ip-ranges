# OpenAI crawlers IP ranges

![Last Commit](https://img.shields.io/github/last-commit/FabrizioCafolla/openai-crawlers-ip-ranges/main) 

Here are the complete and updated lists of OpenAI IP addresses ([Official doc](https://platform.openai.com/docs/bots/overview-of-openai-crawlers)).

**Why this list?** For some time I have been receiving many requests from `user-agent` signed by OpenAI and by researching on the web I realized that I am not the only one. One way to block the bot crawl is to insert it into the `robots.txt` file but apparently this is not enough to block the page scanning.

The possibilities can be of various types:

1. OpenAI ignores the robots and still performs the scans ([see discussion](https://www.reddit.com/r/selfhosted/comments/1i154h7/openai_not_respecting_robotstxt_and_being_sneaky/))
2. Malicious bots impersonating the OpenAI `user-agent` and performing page scraping ([see discussion](https://community.openai.com/t/are-the-documented-gptbot-ip-egress-ranges-up-to-date/509376/1))

## How to block OpenAI User-agents

### Block User-Agent

- [Clouflare](https://developers.cloudflare.com/waf/tools/user-agent-blocking/)
- Nginx
  - Add this snippet to the `server` configuration

    ```nginx
    if ($http_user_agent ~* (GPTBot|ChatGPT-User|OAI-SearchBot)) {
        return 403;
    }
    ```

### IP Block

- [Cloudflare](https://developers.cloudflare.com/learning-paths/secure-internet-traffic/build-dns-policies/create-list/)
- [Cloudfront](https://docs.aws.amazon.com/waf/latest/developerguide/classic-listing-managed-ips.html)
- [Akami](https://techdocs.akamai.com/aura-network-policy/reference/put-blocklist)
- [Fastly](https://docs.fastly.com/en/guides/using-the-ip-block-list)
- Nginx
  - Create a file like `/etc/nginx/blocked_ips.conf` and add the list of IPs to block:

    ```nginx
    deny x.y.z.w;
    ...
    ```

  - Add `include /etc/nginx/blocked_ips.conf;` to the `server` configuration

### Block spam user-agents

Configuration to block all user-agent requests coming from unofficial IPs

```nginx
geo $allowedipaddr {
    default             1;
    20.42.10.176        0; # <-- Official OpenAI IPs
    172.203.190.128     0; # <-- Official OpenAI IPs    
    51.8.102.0          0; # <-- Official OpenAI IPs     
    ...
}

map $http_user_agent $block_spam_user_agent {
    '~*GPTBot'                 $allowedipaddr;
    '~*ChatGPT-User'           $allowedipaddr;
    '~*OAI-SearchBot'          $allowedipaddr;
    default                    0;
}

server {
    ...
    location / {
      ...
      if ($block_spam_user_agent) { return 403; }
    }
}
```

**If you want to test in local env (with docker)**

```bash
docker network create test-network
docker run --name test-nginx --rm -d -p 80:80 --network test-network nginx:alpine
docker run --name test-app --rm -d -it --network test-network python:alpine ash 

docker inspect test-nginx | grep IPAddress # Get IP Address: <nginx_ip_address>
docker inspect test-app | grep IPAddress # Get IP Address: <app_ip_address>

docker exec -it test-nginx ash
# Now you are inside to nginx container
$ vi etc/nginx/conf.d/default.conf
$ # ...Paste nginx configuration and add <app_ip_address> to "geo $allowedipaddr"
$ nginx -s reload -c /etc/nginx/nginx.conf
$ exit

docker exec -it test-app ash
$ apk add curl
$ curl --user-agent "ChatGPT-User" <nginx_ip_address>
$ # Response: nginx welcome page
$ exit
```

## All OpenAI IPs

- [**List of all IPs**](openai/openai-ip-ranges-all.txt)

### ChatGPT User IP

- [**IPs list**](openai/openai-ip-ranges-chatgpt-user.txt)
- **User Agent**: `Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko); compatible; ChatGPT-User/1.0; +https://openai.com/bot`

### GPTBot IP

- [**IPs List**](openai/openai-ip-ranges-gptbot.txt)
- **User Agent**:  `Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko); compatible; GPTBot/1.1; +https://openai.com/gptbot`

### SearchBot IP

- [**IPs List**](openai/openai-ip-ranges-searchbot.txt)
- **User Agent**:  `OAI-SearchBot/1.0; +https://openai.com/searchbot`
