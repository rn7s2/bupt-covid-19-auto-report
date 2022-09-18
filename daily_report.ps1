function report {
    param ($round)

    try {
        Write-Host "第 $round 次尝试";

        if ($null -eq $env:DAILY_REPORT_FORM) {
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

        Write-Host "开始每日打卡";

        $body = ConvertFrom-Json $env:DAILY_REPORT_FORM -AsHashtable;
        $body.Remove("date");
        $body.Remove("uid");
        $body.Remove("id");
        $body.Remove("created");
        $body = $body + @{"date" = (Get-Date).AddHours(8).ToString("yyyyMMdd") }

        $res = Invoke-WebRequest -UseBasicParsing -Uri "https://app.bupt.edu.cn/ncov/wap/default/save" `
            -Method "POST" `
            -TimeoutSec 360 `
            -WebSession $session `
            -Headers @{
            "sec-ch-ua"          = "`" Not A;Brand`"; v=`"99`", `"Chromium`"; v=`"96`", `"Google Chrome`"; v=`"96`""
            "Accept"             = "application/json, text/javascript, */*; q=0.01"
            "X-Requested-With"   = "XMLHttpRequest"
            "sec-ch-ua-mobile"   = "?1"
            "sec-ch-ua-platform" = "`"Android`""
            "Origin"             = "https://app.bupt.edu.cn"
            "Sec-Fetch-Site"     = "same-origin"
            "Sec-Fetch-Mode"     = "cors"
            "Sec-Fetch-Dest"     = "empty"
            "Referer"            = "https://app.bupt.edu.cn/ncov/wap/default/index"
            "Accept-Encoding"    = "gzip, deflate, br"
            "Accept-Language"    = "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6"
        } `
            -ContentType "application/x-www-form-urlencoded; charset=UTF-8" `
            -Body $body;

        if ($res.StatusCode -ne 200 -or (ConvertFrom-Json $res.Content).e -ne 0) {
            Write-Host $res.Content;
            throw "打卡失败";
        }

        Write-Host $res.Content;
        Write-Host "每日填报成功";
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
