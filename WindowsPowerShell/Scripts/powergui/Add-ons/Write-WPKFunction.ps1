0.$2d_1 = window.setTimeout(this.$7y, 100);
        }
    },
    
    onToolTipOpenned: function() {ULSpEN:;
        this.$70_0 = this.$8H;
        this.$6z_0 = this.$1S_0.$1G;
        $addHandler(document, 'keydown', this.$70_0);
        $addHandler(document, 'click', this.$6z_0);
    },
    
    onToolTipClosed: function() {ULSpEN:;
        $removeHandler(document, 'keydown', this.$70_0);
        $removeHandler(document, 'click', this.$6z_0);
    },
    
    onHelpKeyPress: function($p0) {
        if (!CUI.ScriptUtility.isNullOrUndefined(this.$1S_0)) {
            this.$1S_0.$Ar($p0);
        }
    },
    
    launchToolTip: function() {ULSpEN:;
        if (CUI.ScriptUtility.isNullOrUndefined(this.$0_0)) {
            return;
        }
        window.clearInterval(this.$0_0.$2d_1);
        if (this.$5j_0) {
            return;
        }
        if ((!CUI.ScriptUtility.isNullOrUndefined(this.$0_0.$33_1)) && (this.$0_0.$33_1.$6_0 !== this.$6_0)) {
            this.$0_0.$2f();
        }
        if (CUI.ScriptUtility.isNullOrUndefined(this.$5_0.ToolTipTitle)) {
            return;
        }
        this.$1S_0 = new CUI.ToolTip(this.$0_0, this.$6_0 + '_ToolTip', this.$5_0.ToolTipTitle, this.$5_0.ToolTipDescription, this.$5_0);
        if (!this.get_enabled()) {
            var $v_1 = new CUI.DisabledCommandInfoProperties();
            $v_1.Icon = this.$0_0.$5_1.ToolTipDisabledCommandImage16by16;
            $v_1.IconClass = this.$0_0.$5_1.ToolTipDisabledCommandImage16by16Class;
            $v_1.IconTop = this.$0_0.$5_1.ToolTipDisabledCommandImage16by16Top;
            $v_1.IconLeft = this.$0_0.$5_1.ToolTipDisabledCommandImage16by16Left;
            $v_1.Title = this.$0_0.$5_1.ToolTipDisabledCommandTitle;
            $v_1.Description = this.$0_0.$5_1.ToolTipDisabledCommandDescription;
            $v_1.HelpKeyWord = this.$0_0.$5_1.ToolTipDisabledCommandHelpKey;
            this.$1S_0.$1B_1 = $v_1;
        }
        var $v_0 = this.get_displayedComponent();
        $v_0.$7D();
        $v_0.addChild(this.$1S_0);
        this.$1S_0.$CT();
        this.$5j_0 = true;
        this.$0_0.$33_1 = this;
        this.onToolTipOpenned();
    },
    
    $X: function() {ULSpEN:;
        if (!CUI.ScriptUtility.isNullOrUndefined(this.$0_0)) {
            window.clearInterval(this.$0_0.$2d_1);
        }
        if (!CUI.ScriptUtility.isNullOrUndefined(this.$1S_0)) {
            this.$1S_0.$Aa();
            this.$5j_0 = false;
            this.onToolTipClosed();
            CUI.UIUtility.removeNode(this.$1S_0.get_$2());
            this.$1S_0 = null;
        }
    },
    
    get_enabled: function() {ULSpEN:;
        return this.$1P_0;
    },
    set_enabled: function($p0) {
        if (this.$1P_0 === $p0 && this.$5U_0) {
            return;
        }
        this.$1P_0 = $p0;
        this.$5U_0 = true;
        this.onEnabledChanged($p0);
        return $p0;
    },
    
    get_enabledInternal: function() {ULSpEN:;
        return this.$1P_0;
    },
    set_enabledInternal: function($p0) {
        this.$1P