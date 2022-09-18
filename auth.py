import os
import json
from helium import *
from pathlib import Path

TIMEOUT = 360


def auth(round):
    try:
        print('attempt to auth, round ', round)

        start_firefox(
            'https://app.bupt.edu.cn/site/ncov/xisudailyup', headless=True)

        wait_until(Text("密码登录").exists, TIMEOUT)
        click("密码登录")
        wait_until(Button('账号登录').exists, TIMEOUT)

        click(S('#username'))
        write(os.getenv('USERNAME'))
        click(S('#password'))
        write(os.getenv('PASSWORD'))
        click(Button('账号登录'))

        wait_until(Text('除每日填报，午晚检在此填报。').exists, TIMEOUT)

        Path('cookies.txt').write_text(json.dumps(get_driver().get_cookies()))

        kill_browser()

        print('认证成功')
    except:
        if round >= 2:
            raise Exception('失败次数过多')
        else:
            auth(round + 1)


auth(0)
