// ==MiruExtension==
// @name         Tamilarasan
// @version      v0.0.2
// @author       Miru
// @lang         ta
// @license      MIT
// @type         bangumi
// @package      online.tamilarasan
// @webSite      https://tamilarasan.online
// @description  Watch Tamil Movies, Web Series and TV Shows on Tamilarasan
// ==/MiruExtension==

export default class Tamilarasan extends Extension {
  async latest(page) {
    const url = page === 1 ? '/trending/' : `/trending/page/${page}/`;
    const res = await this.request(url);
    const list = [];
    const articles = res.match(/<article[^>]*>[\s\S]*?<\/article>/g) || [];

    for (const art of articles) {
      const urlMatch = art.match(/href=["']([^"']+)["']/);
      const imgMatch = art.match(/src=["']([^"']+)["']/);
      const titleMatch = art.match(/<h3[^>]*class=["']title["'][^>]*>(.*?)<\/h3>/s) || art.match(/alt=["']([^"']+)["']/);

      if (urlMatch && titleMatch) {
        const title = titleMatch[1].replace(/<[^>]+>/g, '').trim();
        const cover = imgMatch ? imgMatch[1] : '';
        list.push({
          title,
          url: urlMatch[1],
          cover,
        });
      }
    }
    return list;
  }

  async search(kw, page) {
    const url = page === 1 ? `/?s=${encodeURIComponent(kw)}` : `/page/${page}/?s=${encodeURIComponent(kw)}`;
    const res = await this.request(url);
    const list = [];
    const articles = res.match(/<article[^>]*>[\s\S]*?<\/article>/g) || [];

    for (const art of articles) {
      const urlMatch = art.match(/href=["']([^"']+)["']/);
      const imgMatch = art.match(/src=["']([^"']+)["']/);
      const titleMatch = art.match(/<div class=["']title["'][^>]*>\s*<a[^>]*>(.*?)<\/a>/s) || art.match(/<h3[^>]*class=["']title["'][^>]*>(.*?)<\/h3>/s) || art.match(/alt=["']([^"']+)["']/);

      if (urlMatch && titleMatch) {
        const title = titleMatch[1].replace(/<[^>]+>/g, '').trim();
        const cover = imgMatch ? imgMatch[1] : '';
        list.push({
          title,
          url: urlMatch[1],
          cover,
        });
      }
    }
    return list;
  }

  async detail(url) {
    const res = await this.request(url);

    const titleMatch = res.match(/<h1[^>]*>(.*?)<\/h1>/s);
    const title = titleMatch ? titleMatch[1].replace(/<[^>]+>/g, '').trim() : '';

    const coverMatch = res.match(/<div class=["']poster["'][^>]*>\s*<img[^>]+src=["']([^"']+)["']/s) || res.match(/<img[^>]+src=["']([^"']+)["']/);
    const cover = coverMatch ? coverMatch[1] : '';

    const descMatch = res.match(/<div class=["']wp-content["'][^>]*>([\s\S]*?)<\/div>/) || res.match(/<div[^>]+id=["']info["'][^>]*>([\s\S]*?)<\/div>/);
    let desc = descMatch ? descMatch[1].replace(/<script[\s\S]*?<\/script>/gi, '').replace(/<[^>]+>/g, '').trim() : '';

    const episodeUrls = [];
    const iframes = res.match(/<iframe[^>]+src=["']([^"']+)["']/gi) || [];

    for (let i = 0; i < iframes.length; i++) {
      const srcMatch = iframes[i].match(/src=["']([^"']+)["']/i);
      if (srcMatch) {
        let iframeUrl = srcMatch[1];
        if (iframeUrl.startsWith('//')) {
          iframeUrl = 'https:' + iframeUrl;
        }
        if (!iframeUrl.includes('facebook.com') && !iframeUrl.includes('twitter.com') && !iframeUrl.includes('google.com')) {
          let epName = `Player ${i + 1}`;
          if (iframeUrl.includes('ok.ru')) {
            epName += ' (OK.ru)';
          } else if (iframeUrl.includes('voe.sx')) {
            epName += ' (Voe)';
          } else if (iframeUrl.includes('morencius.com')) {
            epName += ' (Morencius)';
          }
          episodeUrls.push({
            name: epName,
            url: iframeUrl,
          });
        }
      }
    }

    return {
      title,
      cover,
      desc,
      episodes: [
        {
          title: 'Streams',
          urls: episodeUrls,
        },
      ],
    };
  }

  async watch(url) {
    // 1. Try prov-extractor API first
    try {
      const apiUrl = `https://prov-extractor.vercel.app/api/extract?url=${encodeURIComponent(url)}`;
      const res = await this.request(apiUrl);
      if (res && res.success && res.streamUrl) {
        const isMp4 = res.type === 'video/mp4' || res.streamUrl.includes('.mp4');
        return {
          type: isMp4 ? 'mp4' : 'hls',
          url: res.streamUrl,
          headers: res.headers || {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
        };
      }
    } catch (e) {
      console.log('prov-extractor error: ' + e);
    }

    // 2. Fallback: OK.ru extraction
    if (url.includes('ok.ru')) {
      try {
        const res = await this.request(url);
        const hlsMatch = res.match(/hlsManifestUrl&quot;:&quot;(.*?)&quot;/);
        if (hlsMatch) {
          const hlsUrl = hlsMatch[1].replace(/\\u0026/g, '&');
          return {
            type: 'hls',
            url: hlsUrl,
          };
        }
        const videoMatch = res.match(/&quot;url&quot;:&quot;(.*?)&quot;/g);
        if (videoMatch && videoMatch.length > 0) {
          const lastVideo = videoMatch[videoMatch.length - 1];
          const mp4Url = lastVideo.match(/&quot;url&quot;:&quot;(.*?)&quot;/)[1].replace(/\\u0026/g, '&');
          return {
            type: 'mp4',
            url: mp4Url,
          };
        }
      } catch (e) {
        console.log('Error parsing OK.ru video: ' + e);
      }
    }

    // 3. Fallback: Morencius / VidHide unpacked JS parsing
    if (url.includes('morencius.com')) {
      try {
        const html = await this.request(url);
        const match = html.match(/eval\(function\(p,a,c,k,e,d\)[\s\S]*?\}\s*\(\s*'(.*?)'\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*'([^']*)'\.split\('\|'\)/);
        if (match) {
          let [_, p, a, c, k] = match;
          a = parseInt(a);
          c = parseInt(c);
          const words = k.split('|');

          const toString = (num, radix) => {
            const chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
            if (num === 0) return '0';
            let resStr = '';
            while (num > 0) {
              resStr = chars[num % radix] + resStr;
              num = Math.floor(num / radix);
            }
            return resStr;
          };

          while (c--) {
            if (words[c]) {
              const key = toString(c, a);
              p = p.replace(new RegExp('\\b' + key + '\\b', 'g'), words[c]);
            }
          }

          const m3u8Match = p.match(/https?:\/\/[^\s"'`]+\.m3u8[^\s"'` animate]*/);
          if (m3u8Match) {
            return {
              type: 'hls',
              url: m3u8Match[0],
            };
          }
        }
      } catch (e) {
        console.log('Error unpacking Morencius: ' + e);
      }
    }

    // Default fallback
    return {
      type: 'hls',
      url: url,
    };
  }
}
