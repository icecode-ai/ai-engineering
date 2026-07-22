package com.sample.clean.app.jingdong;

import com.google.auto.service.AutoService;
import com.icecode.clean.extension.App;
import com.icecode.clean.extension.bo.Input;
import com.sample.clean.app.jingdong.common.Constants;
import com.sample.clean.common.BaseInput;

/**
 * JingDong 业务扩展
 *
 * @author jim
 * @date 2013-05-21
 */
@AutoService(App.class)
public class JingDongApp implements App {

    @Override
    public String parseBizCode(Input input) {

        if (input instanceof BaseInput baseInput) {
            if (baseInput.getItemTags().contains(1)) {
                return Constants.BIZ_CODE;
            }
        }

        return null;
    }
}
