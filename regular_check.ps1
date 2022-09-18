function report {
    param ($round)
    
    try {
        Write-Host "第 $round 次尝试";

        if ($null -eq $env:IS_AT_SCHOOL) {
            throw "Secrets参数未设置，请参考README."
        }

        $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession;
        $session.UserAgent = "Mozilla/5.0 (Linux; Android 11; IN2010 Build/RP1A.201005.001; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/86.0.4240.99 XWEB/3171 MMWEBSDK/20211202 Mobile Safari/537.36 MMWEBID/7693 MicroMessenger/8.0.18.2060 (0x28001237) Process/toolsmp WeChat/arm32 Weixin NetType/4G Language/zh_CN ABI/arm64";

        $cookies = ConvertFrom-Json(Get-Content 'cookies.txt');

        foreach ($cookie in $cookies) {
            $cas = New-Object -TypeName System.Net.Cookie;
            $cas.Name = $cookie.name;
            $cas.Value = $cookie.value;
            $cas.Path = $cookie.path;
            $cas.Domain = $cookie.domain;
            $cas.Secure = $cookie.secure;
            $cas.HttpOnly = $cookie.httpOnly;
            $cas.Expires = [System.DateTime]::Now + (New-Object -TypeName System.TimeSpan -ArgumentList 0, 0, 0, 0, $cookie.expiry)
            $session.Cookies.Add($cas);
        }

        Write-Host "开始获取现存填报数据";

        $res = Invoke-WebRequest -UseBasicParsing -Uri "https://app.bupt.edu.cn/xisuncov/wap/open-report/index" `
            -WebSession $session `
            -TimeoutSec 360 `
            -Headers @{
            "sec-ch-ua"          = "`" Not A;Brand`"; v=`"99`", `"Chromium`"; v=`"96`", `"Google Chrome`"; v=`"96`""
            "Accept"             = "application/json, text/plain, */*"
            "X-Requested-With"   = "XMLHttpRequest"
            "sec-ch-ua-mobile"   = "?1"
            "sec-ch-ua-platform" = "`"Android`""
            "Sec-Fetch-Site"     = "same-origin"
            "Sec-Fetch-Mode"     = "cors"
            "Sec-Fetch-Dest"     = "empty"
            "Referer"            = "https://app.bupt.edu.cn/site/ncov/xisudailyup"
            "Accept-Encoding"    = "gzip, deflate, br"
            "Accept-Language"    = "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6"
        };

        $content = ConvertFrom-Json($res.Content);
        if ($res.StatusCode -ne 200 -or $content.e -ne 0) {
            Write-Host $res.Content;
            throw "现存填报数据获取失败，手动填报一次可能会解决问题";
        }
        $data = $content.d.info;

        Write-Host "获取现存填报数据成功，开始晨午晚检打卡";

        $res = Invoke-WebRequest -UseBasicParsing -Uri "https://app.bupt.edu.cn/xisuncov/wap/open-report/save" `
            -Method "POST" `
            -TimeoutSec 360 `
            -WebSession $session `
            -Headers @{
            "sec-ch-ua"          = "`" Not A;Brand`"; v=`"99`", `"Chromium`"; v=`"96`", `"Google Chrome`"; v=`"96`""
            "Accept"             = "application/json, text/plain, */*"
            "X-Requested-With"   = "XMLHttpRequest"
            "sec-ch-ua-mobile"   = "?1"
            "sec-ch-ua-platform" = "`"Android`""
            "Origin"             = "https://app.bupt.edu.cn"
            "Sec-Fetch-Site"     = "same-origin"
            "Sec-Fetch-Mode"     = "cors"
            "Sec-Fetch-Dest"     = "empty"
            "Referer"            = "https://app.bupt.edu.cn/site/ncov/xisudailyup"
            "Accept-Encoding"    = "gzip, deflate, br"
            "Accept-Language"    = "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6"
        } `
            -ContentType "application/x-www-form-urlencoded" `
            -Body @{
            "sfzx"         = $env:IS_AT_SCHOOL
            "tw"           = 1
            "area"         = $data.area
            "city"         = $data.city
            "province"     = $data.province
            "address"      = $data.address
            "geo_api_info" = $data.geo_api_info
            "sfcyglq"      = 0
            "sfyzz"        = 0
            "qtqk"         = ''
            "askforleave"  = 0
        };

        if ($res.StatusCode -ne 200 -or (ConvertFrom-Json $res.Content).e -ne 0) {
            Write-Host $res.Content;
            throw "打卡失败";
        }

        Write-Host $res.Content;
        Write-Host "晨晚午检打卡成功";
    } catch {
        if ($round -ge 2) {
            Write-Host $_;
            throw "失败次数过多";
        } else {
            report ($round + 1);
        }
    }
}

report 0
