if (!this.get_enabled() || this.$i_1) {
            return;
        }
        this.$39_2();
    },
    
    onBlur: function($p0) {
        if (!this.get_enabled() || this.$i_1) {
            return;
        }
        this.$1U_2();
    },
    
    onClick: function($p0) {
        $p0.preventDefault();
        if (!this.get_enabled() || CUI.ScriptUtility.isNullOrUndefined($p0) || $p0.button) {
            return;
        }
        if (this.$i_1) {
            this.$4o();
            return;
        }
        this.$Ai_2();
    },
    
    onKeyPress: function($p0) {
        if (!this.get_enabled()) {
            return;
        }
        if (!$p0 || !$p0.rawEvent) {
            return;
        }
        var $v_0 = $p0.rawEvent.keyCode;
        if ($v_0 === 13 || $v_0 === 32 || $v_0 === 40) {
            this.$1E_1 = true;
            if (this.$i_1) {
                this.$4o();
            }
            else {
                this.$Ai_2();
            }
            $p0.preventDefault();
        }
    },
    
    onContextMenu: function($p0) {
        if (!CUI.ScriptUtility.isNullOrUndefined($p0)) {
            $p0.preventDefault();
        }
    },
    
    $Ai_2: function() {ULSpEN:;
        if (CUI.ScriptUtility.isNullOrUndefined(this.get_properties().ImageDown)) {
            return;
        }
        if (!this.$2w_2) {
            this.$1t_2.src = this.get_properties().ImageDown;
            if (!CUI.ScriptUtility.isNullOrUndefined(this.get_properties().ImageDownClass)) {
                this.$1t_2.className = this.get_properties().ImageDownClass;
            }
        }
        else {
            if (this.$1J_2) {
                CUI.Utility.$1h(this.$1J_2, this.get_properties().ImageLeftSideDown, this.get_properties().ImageLeftSideDownClass, this.get_properties().ImageLeftSideDownTop, this.get_properties().ImageLeftSideDownLeft, null, this.get_properties().Height);
            }
            CUI.Utility.$1h(this.$1Z_2, this.get_properties().ImageDown, this.get_properties().ImageDownClass, this.get_properties().ImageDownTop, this.get_properties().ImageDownLeft, null, this.get_properties().Height);
            if (this.$1K_2) {
                CUI.Utility.$1h(this.$1K_2, this.get_properties().ImageRightSideDown, this.get_properties().ImageRightSideDownClass, this.get_properties().ImageRightSideDownTop, this.get_properties().ImageRightSideDownLeft, null, this.get_properties().Height);
            }
        }
        this.launchMenuInternal(this.$H_2);
    },
    
    onLaunchedMenuClosed: function() {ULSpEN:;
        this.$1U_2();
        this.get_displayedComponent().raiseCommandEvent(this.get_properties().CommandMenuClose, 10, null);
    },
    
    launchMenuInternal: function($p0) {
        this.launchMenu($p0);
        this.get_displayedComponent().raiseCommandEvent(this.get_properties().CommandMenuOpen, 4, null);
    },
    
    $39_2: function() {ULSpEN:;
        if (CUI.ScriptUtility.isNullOrUndefined(this.get_properties().ImageHover)) {
            return;
        }
        if (!this.$2w_2) {
            this.$1t_2.src = this.get_properties().ImageHover;
            if (!CUI.ScriptUtility.isNullOrUndefined(this.get_properties().ImageHoverClass)) {
                this.$1t_2.className = this.get_properties().ImageHoverClass;
            }
        }
        else {
            if (this.$1J_2) {
                CUI.Utility.$1h(this.$1J_2, this.get_properties().ImageLeftSideHover, this.get_properties().ImageLeftSideHoverClass, this.get_properties().ImageLeftSideHoverTop, this.get_properties().ImageLeftSideHoverLeft, null, this.get_properties().Height);
            }
            CUI.Utility.$1h(this.$1Z_2, this.get_properties().ImageHover, this.get_properties().ImageHoverClass, this.get_properties().ImageHoverTop, this.get_properties().ImageHoverLeft, null, this.get_properties().Height);
            if (this.$1K_2) {
                CUI.Utility.$1h(this.$1K_2, this.get_properties().ImageRightSideHover, this.get_properties().ImageRightSideHoverClass, this.get_properties().ImageRightSideHoverTop, this.get_properties().ImageRightSideHoverLeft, null, this.get_properties().Height);
            }
        }
    },
    
    $1U_2: function() {ULSpEN:;
        if (CUI.ScriptUtility.isNullOrUndefined(this.get_properties().ImageHover)) {
            return;
        }
        if (!this.$2w_2) {
            this.$1t_2.src = this.get_properties().Image;
            if (!CUI.ScriptUtility.isNullOrUndefined(this.get_properties().ImageClass)) {
                this.$1t_2.className = this.get_properties().ImageClass;
            }
        }
        else {
            if (this.$1J_2) {
                CUI.Utility.$1h(this.$1J_2, this.get_properties().ImageLeftSide, this.get_properties().ImageLeftSideClass, this.get_properties().ImageLeftSideTop, this.get_properties().ImageLeftSideLeft, null, this.get_properties().Height);
            }
            CUI.Utility.$1h(this.$1Z_2, this.get_properties().Image, this.get_properties().ImageClass, this.get_properties().ImageTop, this.get_properties().ImageLeft, null, this.get_properties().Height);
            if (this.$1K_2) {
                CUI.Utility.$1h(this.$1K_2, this.get_properties().ImageRightSide, this.get_properties().ImageRightSideClass, this.get_properties().ImageRightSideTop, this.get_properties().ImageRightSideLeft, null, this.get_properties().Height);
            }
        }
    },
    
    get_properties: function() {ULSpEN:;
        return this.$5_0;
    },
    
    $Cs: function() {ULSpEN:;
        this.$H_2.focus();
    }
}


Type.registerNamespace('CUI.Page');

CUI.Page.CommandDispatcher = function() {ULSpEN:;
    this.$2L_0 = {};
}
CUI.Page.CommandDispatcher.prototype = {
    $2L_0: null,
    
    $7U: function() {
    },
    
    $5h_0: 0,
    
    getNextSequenceNumber: function() {ULSpEN:;
        if (this.$5h_0 + 1 < 0) {
            throw Error.create('Command Dispatcher sequence numbers overflowed into negative numbers.');
        }
        return ++this.$5h_0;
    },
    
    peekNextSequenceNumber: function() {ULSpEN:;
        return this.$5h_0 + 1;
    },
    
    getLastSequenceNumber: function() {ULSpEN:;
        return this.$5h_0;
    },
    
    executeCommand: function(commandId, properties) {ULSpEN:;
        return this.$Cl(commandId, properties, this.getNextSequenceNumber());
    },
    
    $Cl: function($p0, $p1, $p2) {
        var $v_0 = this.$2L_0[$p0];
        if (CUI.ScriptUtility.isNullOrUndefined($v_0)) {
            return false;
        }
        else if (Array.isInstanceOfType($v_0)) {
            var $v_1 = $v_0;
            var $v_2 = false;
            for (var $v_3 = 0; $v_3 < $v_1.length; $v_3++) {
                var $v_4 = $v_1[$v_3];
                if (this.callCommandHandler($v_4, $p0, $p1, $p2)) {
                    $v_2 = true;
                }
            }
            return $v_2;
        }
        else {
            return this.callCommandHandler($v_0, $p0, $p1, $p2);
        }
    },
    
    isCommandEnabled: function(commandId) {ULSpEN:;
        var $v_0 = this.$2L_0[commandId];
        if (CUI.ScriptUtility.isNullOrUndefined($v_0)) {
            return false;
        }
        else if (Array.isInstanceOfType($v_0)) {
            var $v_1 = $v_0;
            for (var $v_2 = 0; $v_2 < $v_1.length; $v_2++) {
                var $v_3 = $v_1[$v_2];
                if (this.callCommandHandlerForEnabled($v_3, commandId)) {
                    return true;
                }
            }
            return false;
        }
        else {
            return this.callCommandHandlerForEnabled($v_0, commandId);
        }
    },
    
    $AQ: function($p0) {
        return this.$2L_0[$p0];
    },
    
    registerCommandHandler: function(commandId, handler) {ULSpEN:;
        if (CUI.ScriptUtility.isNullOrUndefined(commandId) || CUI.ScriptUtility.isNullOrUndefined(handler)) {
            throw Error.create('commandId and handler may not be null or undefined');
        }
        var $v_0 = this.$2L_0[commandId];
        if (CUI.ScriptUtility.isNullOrUndefined($v_0)) {
            this.$2L_0[commandId] = handler;
        }
        else if (Array.isInstanceOfType($v_0)) {
            if (!Array.contains($v_0, handler)) {
                Array.add($v_0, handler);
            }
        }
        else {
            if ($v_0 === handler) {
                return;
            }
            var $v_1 = [];
            Array.add($v_1, $v_0);
            Array.add($v_1, handler);
            this.$2L_0[commandId] = $v_1;
        }
    },
    
    unregisterCommandHandler: function(commandId, handler) {ULSpEN:;
        if (CUI.ScriptUtility.isNullOrUndefined(commandId) || CUI.ScriptUtility.isNullOrUndefined(handler)) {
            throw Error.create('commandId and handler may not be null or undefined');
        }
        var $v_0 = this.$2L_0[commandId];
        if (CUI.ScriptUtility.isNullOrUndefined($v_0)) {
            return;
        }
        else if (Array.isInstanceOfType($v_0)) {
            Array.remove($v_0, handler);
        }
        else {
            if ($v_0 === handler) {
                this.$2L_0[commandId] = null;
            }
        }
    },
    
    registerMultipleCommandHandler: function(component, commands) {ULSpEN:;
        for (var $v_0 = 0; $v_0 < commands.length; $v_0++) {
            this.registerCommandHandler(commands[$v_0], component);
        }
    },
    
    unregisterMultipleCommandHandler: function(component, commands) {ULSpEN:;
        for (var $v_0 = 0; $v_0 < commands.length; $v_0++) {
            this.unregisterCommandHandler(commands[$v_0], component);
        }
    },
    
    callCommandHandler: function(handler, commandId, properties, sequenceNumber) {ULSpEN:;
        return handler.handleCommand(commandId, properties, sequenceNumber);
    },
    
    callCommandHandlerForEnabled: function(handler, commandId) {ULSpEN:;
        return handler.canHandleCommand(commandId);
    }
}


CUI.Page.FocusManager = function(pageManager) {ULSpEN:;
    CUI.Page.FocusManager.initializeBase(this);
    this.$23_1 = pageManager;
    this.$k_1 = [];
    this.$2b_1 = {};
    this.$1N_1 = [];
    this.$2X_1 = {};
}
CUI.Page.FocusManager.prototype = {
    $1N_1: null,
    $2b_1: null,
    $23_1: null,
    $2X_1: null,
    
    $7U: function() {
    },
    
    $AZ_1: function() {ULSpEN:;
        this.$2X_1 = {};
        var $v_0 = this.$1N_1.length;
        for (var $v_1 = 0; $v_1 < $v_0; $v_1++) {
            var $v_2 = this.$1N_1[$v_1];
            this.$2X_1[($v_2)] = $v_2;
        }
    },
    
    requestFocusForComponent: function(component) {ULSpEN:;
        if (CUI.ScriptUtility.isNullOrUndefined(component)) {
            return false;
        }
        if (Array.contains(this.$1N_1, component)) {
            return true;
        }
        Array.add(this.$1N_1, component);
        this.$AZ_1();
        component.receiveFocus();
        return true;
    },
    
    releaseFocusFromComponent: function(component) {ULSpEN:;
        if (CUI.ScriptUtility.isNullOrUndefined(component)) {
            return false;
        }
        if (!Array.contains(this.$1N_1, component)) {
            return true;
        }
        Array.remove(this.$1N_1, component);
        this.$AZ_1();
        component.yieldFocus();
        return true;
    },
    
    releaseAllFoci: function() {ULSpEN:;
        this.$2X_1 = {};
        var $v_0 = this.$1N_1.length;
        for (var $v_1 = $v_0 - 1; $v_1 >= 0; $v_1--) {
            var $v_2 = this.$1N_1[$v_1];
            Array.remove(this.$1N_1, $v_2);
            $v_2.yieldFocus();
        }
        return true;
    },
    
    getFocusedComponents: function() {ULSpEN:;
        return Array.clone(this.$1N_1);
    },
    
    handleCommand: function(commandId, properties, sequenceNumber) {ULSpEN:;
        var $v_0 = this.$AQ(commandId);
        if (CUI.ScriptUtility.isNullOrUndefined($v_0)) {
            return false;
        }
        else if (Array.isInstanceOfType($v_0)) {
            var $v_1 = $v_0;
            for (var $v_2 = 0; $v_2 < $v_1.length; $v_2++) {
                var $v_3 = $v_1[$v_2];
                if (CUI.ScriptUtility.isNullOrUndefined(this.$2X_1[$v_3])) {
                    continue;
                }
                if (this.callCommandHandler($v_3, commandId, properties, sequenceNumber)) {
                    return true;
                }
            }
            return false;
        }
        else {
            if (CUI.ScriptUtility.isNullOrUndefined(this.$2X_1[$v_0])) {
                return false;
            }
            return this.callCommandHandler($v_0, commandId, properties, sequenceNumber);
        }
    },
    
    canHandleCommand: function(commandId) {ULSpEN:;
        var $v_0 = this.$AQ(commandId);
        if (CUI.ScriptUtility.isNullOrUndefined($v_0)) {
            return false;
        }
        else if (Array.isInstanceOfType($v_0)) {
            var $v_1 = $v_0;
            for (var $v_2 = 0; $v_2 < $v_1.length; $v_2++) {
                var $v_3 = $v_1[$v_2];
                if (CUI.ScriptUtility.isNullOrUndefined(this.$2X_1[$v_3])) {
                    continue;
                }
                if (this.callCommandHandlerForEnabled($v_3, commandId)) {
                    return true;
                }
            }
            return false;
        }
        else {
            if (CUI.ScriptUtility.isNullOrUndefined(this.$2X_1[$v_0])) {
                return false;
            }
            return this.callCommandHandlerForEnabled($v_0, commandId);
        }
    },
    
    $k_1: null,
    
    $BY: function($p0) {
        if (Array.contains(this.$k_1, $p0)) {
            return;
        }
        this.registerMultipleCommandHandler($p0, $p0.getFocusedCommands());
        Array.add(this.$k_1, $p0);
    },
    
    $Dw: function($p0) {
        if (!Array.contains(this.$k_1, $p0)) {
            return;
        }
        this.unregisterMultipleCommandHandler($p0, $p0.getFocusedCommands());
        this.releaseFocusFromComponent($p0);
        Array.remove(this.$k_1, $p0);
    },
    
    executeCommand: function(commandId, properties) {ULSpEN:;
        throw Error.create('ExecuteCommand should not be called on the main CommandDispatcher of the page, not the FocusManager');
    },
    
    registerCommandHandler: function(commandId, handler) {ULSpEN:;
        CUI.Page.FocusManager.callBaseMethod(this, 'registerCommandHandler', [ commandId, handler ]);
        if (CUI.ScriptUtility.isNullOrUndefined(this.$2b_1[commandId])) {
            this.$23_1.$z_1.registerCommandHandler(commandId, this);
            this.$2b_1[commandId] = 0;
        }
        var $v_0 = this.$2b_1[commandId];
        this.$2b_1[commandId] = $v_0 + 1;
    },
    
    unregisterCommandHandler: function(commandId, handler) {ULSpEN:;
        CUI.Page.FocusManager.callBaseMethod(this, 'unregisterCommandHandler', [ commandId, handler ]);
        var $v_0 = this.$2b_1[commandId];
        if (!CUI.ScriptUtility.isNullOrUndefined($v_0) && $v_0 > 0) {
            this.$2b_1[commandId] = --$v_0;
            if ($v_0 <= 0) {
                this.$23_1.$z_1.unregisterCommandHandler(commandId, this);
                delete this.$2b_1[commandId];
            }
        }
    },
    
    getNextSequenceNumber: function() {ULSpEN:;
        throw Error.create('The FocusManager does not issue command sequence numbers.  This is only done by the main CommandDispatcher of the page.');
    },
    
    peekNextSequenceNumber: function() {ULSpEN:;
        throw Error.create('The FocusManager does not issue command sequence numbers.  This is only done by the main CommandDispatcher of the page.');
    },
    
    getLastSequenceNumber: function() {ULSpEN:;
        throw Error.create('The FocusManager does not issue command sequence numbers.  This is only done by the main CommandDispatcher of the page.');
    },
    
    callCommandHandler: function(handler, commandId, properties, sequenceNumber) {ULSpEN:;
        if (!Array.contains(this.$1N_1, handler)) {
            return false;
        }
        return handler.handleCommand(commandId, properties, sequenceNumber);
    },
    
    callCommandHandlerForEnabled: function(handler, commandId) {ULSpEN:;
        if (!Array.contains(this.$1N_1, handler)) {
            return false;
        }
        return handler.canHandleCommand(commandId);
    }
}


CUI.Page.PageManager = function() {ULSpEN:;
    this.$59 = Function.createDelegate(this, this.$7Z_1);
    CUI.Page.PageManager.initializeBase(this);
    this.$k_1 = [];
    this.$4C_1 = {};
    this.$z_1 = new CUI.Page.CommandDispatcher();
    this.$3h_1 = new CUI.Page.FocusManager(this);
    this.$5k_1 = new CUI.Page.UndoManager(this);
    this.$2M_1 = [];
    this.$22_1 = this.$59;
    $addHandler(window, 'unload', this.$22_1);
}
CUI.Page.PageManager.initialize = function() {ULSpEN:;
    if (!CUI.ScriptUtility.isNullOrUndefined(CUI.Page.PageManager._instance)) {
        return;
    }
    CUI.Page.PageManager._instance = CUI.Page.PageManager.createPageManager();
    CUI.Page.PageManager._instance.initializeInternal();
}
CUI.Page.PageManager.createPageManager = function() {ULSpEN:;
    return new CUI.Page.PageManager();
}
CUI.Page.PageManager.get_instance = function() {ULSpEN:;
    if (!CUI.Page.PageManager._instance) {
        CUI.Page.PageManager.initialize();
    }
    return CUI.Page.PageManager._instance;
}
CUI.Page.PageManager.prototype = {
    $22_1: null,
    
    initializeInternal: function() {ULSpEN:;
        this.$z_1.$7U();
        this.$5k_1.$7U();
        this.$3h_1.$7U();
        this.$z_1.registerCommandHandler('appstatechanged', this);
    },
    
    $7Z_1: function($p0) {
        this.dispose();
    },
    
    dispose: function() {ULSpEN:;
        if (!CUI.ScriptUtility.isNullOrUndefined(this.get_ribbon())) {
            this.get_ribbon().$Cp();
        }
        this.$3h_1 = null;
        this.$5k_1 = null;
        this.$z_1 = null;
        this.$2M_1 = null;
        this.$k_1 = null;
        $addHandler(window, 'unload', this.$22_1);
    },
    
    $z_1: null,
    
    get_commandDispatcher: function() {ULSpEN:;
        return this.$z_1;
    },
    
    $3h_1: null,
    
    get_focusManager: function() {ULSpEN:;
        return this.$3h_1;
    },
    
    $5k_1: null,
    
    get_undoManager: function() {ULSpEN:;
        return this.$5k_1;
    },
    
    $6R_1: null,
    
    get_$7H_1: function() {ULSpEN:;
        if (!this.$6R_1) {
            this.$6R_1 = new Sys.EventHandlerList();
        }
        return this.$6R_1;
    },
    
    $3o_1: null,
    
    get_ribbon: function() {ULSpEN:;
        return this.$3o_1;
    },
    set_ribbon: function(value) {ULSpEN:;
        if (value === this.$3o_1) {
            return;
        }
        if (CUI.ScriptUtility.isNullOrUndefined(value) && !CUI.ScriptUtility.isNullOrUndefined(this.$3o_1)) {
            this.removeRoot(this.$3o_1);
            this.$3o_1 = null;
        }
        else if (!Array.contains(this.$2M_1, value)) {
            this.addRoot(value);
            this.$3o_1 = value;
        }
        return value;
    },
    
    add_ribbonInited: function(value) {ULSpEN:;
        this.get_$7H_1().addHandler('RibbonInited', value);
    },
    remove_ribbonInited: function(value) {ULSpEN:;
        this.get_$7H_1().removeHandler('RibbonInited', value);
    },
    
    onComponentBuilt: function(root, componentId) {ULSpEN:;
        this.pollRootState(root);
        if (CUI.Ribbon.isInstanceOfType(root)) {
            var $v_0 = this.get_$7H_1().getHandler('RibbonInited');
            if ($v_0) {
                $v_0(this, Sys.EventArgs.Empty);
            }
        }
    },
    
    onComponentCreated: function(root, componentId) {ULSpEN:;
        if (CUI.Ribbon.isInstanceOfType(root) && CUI.ScriptUtility.isNullOrUndefined(this.get_ribbon())) {
            this.set_ribbon(root);
        }
        else {
            this.addRoot(root);
        }
    },
    
    $2M_1: null,
    
    addRoot: function(root) {ULSpEN:;
        if (Array.contains(this.$2M_1, root)) {
            throw Error.create('This Root has already been added to the PageManager');
        }
        Array.add(this.$2M_1, root);
        root.set_rootUser(this);
    },
    
    removeRoot: function(root) {ULSpEN:;
        if (!Array.contains(this.$2M_1, root)) {
            throw Error.create('This Root has not been added to the PageManager.');
        }
        Array.remove(this.$2M_1, root);
        root.set_rootUser(null);
    },
    
    $k_1: null,
    $4C_1: null,
    
    getPageComponentById: function(id) {ULSpEN:;
        return this.$4C_1[id];
    },
    
    addPageComponent: function(component) {ULSpEN:;
        if (!CUI.ScriptUtility.isNullOrUndefined(this.$4C_1[component.getId()])) {
            Error.create('A PageComponent with id: ' + component.getId() + ' has already been added to the PageManger.');
        }
        if (!CUI.ScriptUtility.isNullOrUndefined(this.$k_1) && !Array.contains(this.$k_1, component)) {
            this.$4C_1[component.getId()] = component;
            component.init();
            this.$z_1.registerMultipleCommandHandler(component, component.getGlobalCommands());
            Array.add(this.$k_1, component);
            if (component.isFocusable()) {
                this.$3h_1.$BY(component);
            }
        }
    },
    
    removePageComponent: function(component) {ULSpEN:;
        if (CUI.ScriptUtility.isNullOrUndefined(this.$k_1) || !Array.contains(this.$k_1, component)) {
            return;
        }
        this.$z_1.unregisterMultipleCommandHandler(component, component.getGlobalCommands());
        Array.remove(this.$k_1, component);
        if (component.isFocusable()) {
            this.$3h_1.$Dw(component);
        }
        this.$4C_1[component.getId()] = null;
    },
    
    executeRootCommand: function(commandId, properties, commandInfo, root) {ULSpEN:;
        return this.$z_1.executeCommand(commandId, properties);
    },
    
    isRootCommandEnabled: function(commandId, root) {ULSpEN:;
        return this.$z_1.isCommandEnabled(commandId);
    },
    
    onRootRefreshed: function(root) {ULSpEN:;
        if (!CUI.ScriptUtility.isNullOrUndefined(root)) {
            this.pollRootState(root);
        }
    },
    
    handleCommand: function(commandId, properties, sequenceNumber) {ULSpEN:;
        if (commandId === 'appstatechanged') {
            for (var $v_0 = 0; $v_0 < this.$2M_1.length; $v_0++) {
                var $v_1 = this.$2M_1[$v_0];
                this.pollRootState($v_1);
                if ($v_1.$g_0) {
                    $v_1.$L();
                }
            }
            return true;
        }
        return false;
    },
    
    $6q_1: false,
    
    get_rootPollingInProgress: function() {ULSpEN:;
        return this.$6q_1;
    },
    
    pollRootState: function(root) {ULSpEN:;
        try {
            this.$6q_1 = true;
            root.pollForStateAndUpdate();
        }
        finally {
            this.$6q_1 = false;
        }
    },
    
    changeCommandContext: function(commandContextId) {ULSpEN:;
        if (!CUI.ScriptUtility.isNullOrUndefined(this.get_ribbon())) {
            return this.get_ribbon().selectTabByCommand(commandContextId);
        }
        return false;
    },
    
    canHandleCommand: function(commandId) {ULSpEN:;
        return commandId === 'appstatechanged';
    },
    
    restoreFocusToRibbon: function() {ULSpEN:;
        if (!this.get_ribbon().restoreFocus()) {
            this.get_ribbon().setFocus();
        }
    }
}


CUI.Page.UndoManager = function(pageManager) {ULSpEN:;
    this.$6p_0 = CUI.Page.UndoManager.$28_0;
    this.$23_0 = pageManager;
    this.$1F_0 = [];
    this.$14_0 = [];
    this.$25_0 = {};
}
CUI.Page.UndoManager.prototype = {
    $23_0: null,
    $25_0: null,
    $1F_0: null,
    $14_0: null,
    
    $7U: function() {ULSpEN:;
        this.$23_0.$z_1.registerCommandHandler('GlobalUndo', this);
        this.$23_0.$z_1.registerCommandHandler('GlobalRedo', this);
        this.$23_0.$z_1.registerCommandHandler('grpedit', this);
    },
    
    addUndoSequenceNumber: function(sequenceNumber) {ULSpEN:;
        this.$Dr_0(sequenceNumber);
        if (sequenceNumber !== this.$6p_0) {
            this.$CY_0();
        }
    },
    
    addRedoSequenceNumber: function(sequenceNumber) {ULSpEN:;
        this.$Dq_0(sequenceNumber);
    },
    
    get_oldestSequenceNumber: function() {ULSpEN:;
        if (!this.$1F_0.length) {
            return CUI.Page.UndoManager.$28_0;
        }
        var $v_0 = CUI.Page.UndoManager.$28_0;
        var $v_1 = CUI.Page.UndoManager.$28_0;
        if (this.$1F_0.length > 0) {
            $v_0 = this.$1F_0[this.$1F_0.length - 1];
        }
        if (this.$14_0.length > 0) {
            $v_1 = this.$14_0[0];
        }
        if ($v_0 === CUI.Page.UndoManager.$28_0) {
            return $v_0;
        }
        else {
            return $v_0;
        }
    },
    
    $CW_0: function() {ULSpEN:;
        var $v_0 = this.$Dm_0();
        if ($v_0 === CUI.Page.UndoManager.$28_0) {
            return;
        }
        var $v_1 = {};
        $v_1['SequenceNumber'] = $v_0;
        this.$23_0.$z_1.executeCommand('Undo', $v_1);
    },
    
    $CV_0: function() {ULSpEN:;
        var $v_0 = this.$Dl_0();
        if ($v_0 === CUI.Page.UndoManager.$28_0) {
            return;
        }
        var $v_1 = {};
        $v_1['SequenceNumber'] = $v_0;
        this.$6p_0 = this.$23_0.$z_1.peekNextSequenceNumber();
        this.$23_0.$z_1.executeCommand('Redo', $v_1);
    },
    
    $Dl_0: function() {ULSpEN:;
        if (!this.$14_0.length) {
            return CUI.Page.UndoManager.$28_0;
        }
        var $v_0 = this.$14_0[0];
        Array.removeAt(this.$14_0, 0);
        this.$25_0[$v_0.toString()] = null;
        return $v_0;
    },
    
    $Dq_0: function($p0) {
        if (!CUI.ScriptUtility.isNullOrUndefined(this.$25_0[$p0.toString()])) {
            if (this.$1F_0[0] !== $p0) {
                throw Error.create('This command sequence number is already on the undo or the redo stack but it is not ontop of the redo stack.  Pushing it would result in out of sequence redo and undo stacks.');
            }
            return;
        }
        Array.insert(this.$14_0, 0, $p0);
        this.$25_0[$p0.toString()] = $p0;
    },
    
    $Dm_0: function() {ULSpEN:;
        if (!this.$1F_0.length) {
            return CUI.Page.UndoManager.$28_0;
        }
        var $v_0 = this.$1F_0[0];
        Array.removeAt(this.$1F_0, 0);
        this.$25_0[$v_0.toString()] = null;
        return $v_0;
    },
    
    $Dr_0: function($p0) {
        if (!CUI.ScriptUtility.isNullOrUndefined(this.$25_0[$p0.toString()])) {
            if (this.$1F_0[0] !== $p0) {
                throw Error.create('This command sequence number is already on the stack and not on top.  Pushing it would result in an out of sequence undo stack.');
            }
            return;
        }
        Array.insert(this.$1F_0, 0, $p0);
        this.$25_0[$p0.toString()] = $p0;
    },
    
    $CY_0: function() {ULSpEN:;
        for (var $v_0 = 0; $v_0 < this.$14_0.length; $v_0++) {
            this.$25_0[(this.$14_0[$v_0]).toString()] = null;
            Array.remove(this.$14_0, this.$14_0[$v_0]);
        }
        Array.clear(this.$14_0);
    },
    
    invalidateUndoSequenceNumber: function(sequenceNumber) {ULSpEN:;
        for (var $v_0 = this.$1F_0.length - 1; $v_0 > -1; $v_0--) {
            var $v_1 = this.$1F_0[$v_0];
            if ($v_1 <= sequenceNumber) {
                Array.removeAt(this.$1F_0, $v_0);
                this.$25_0[$v_1.toString()] = null;
            }
        }
        while (this.$14_0.length > 0 && this.$14_0[0] <= sequenceNumber) {
            this.$25_0[(this.$14_0[0]).toString()] = null;
            Array.removeAt(this.$14_0, 0);
        }
    },
    
    canHandleCommand: function(commandId) {ULSpEN:;
        if (commandId === 'GlobalUndo') {
            return this.$1F_0.length > 0;
        }
        else if (commandId === 'GlobalRedo') {
            return this.$14_0.length > 0;
        }
        else if (commandId === 'grpedit') {
            return true;
        }
        return false;
    },
    
    handleCommand: function(commandId, properties, sequenceNumber) {ULSpEN:;
        switch (commandId) {
            case 'GlobalUndo':
                this.$CW_0();
                return true;
            case 'GlobalRedo':
                this.$CV_0();
                return true;
        }
        return false;
    }
}


Type.registerNamespace('Commands');

Commands.CommandIds = function() {
}


Commands.GlobalRedoProperties = function() {
}


Commands.RedoProperties = function() {
}


Commands.GlobalUndoProperties = function() {
}


Commands.UndoProperties = function() {
}


CUI.BuildOptions.registerClass('CUI.BuildOptions');
CUI.BuildContext.registerClass('CUI.BuildContext');
CUI.DataNodeWrapper.registerClass('CUI.DataNodeWrapper');
CUI.Builder.registerClass('CUI.Builder', null, Sys.IDisposable);
CUI.CommandEventArgs.registerClass('CUI.CommandEventArgs', Sys.EventArgs);
CUI.Component.registerClass('CUI.Component', null, CUI.IMenuItem, Sys.IDisposable);
CUI.Menu.registerClass('CUI.Menu', CUI.Component);
CUI.ContextMenu.registerClass('CUI.ContextMenu', CUI.Menu);
CUI.ContextMenuDock.registerClass('CUI.ContextMenuDock', CUI.Component);
CUI.Control.registerClass('CUI.Control', null, Sys.IDisposable, CUI.IMenuItem);
CUI.MenuLauncher.registerClass('CUI.MenuLauncher', CUI.Control, CUI.IModalController);
CUI.ContextMenuLauncher.registerClass('CUI.ContextMenuLauncher', CUI.MenuLauncher);
CUI.RootProperties.registerClass('CUI.RootProperties');
CUI.ContextMenuRootProperties.registerClass('CUI.ContextMenuRootProperties', CUI.RootProperties);
CUI.Root.registerClass('CUI.Root', CUI.Component, Sys.IDisposable);
CUI.ContextMenuRoot.registerClass('CUI.ContextMenuRoot', CUI.Root);
CUI.ControlProperties.registerClass('CUI.ControlProperties');
CUI.ControlComponent.registerClass('CUI.ControlComponent', CUI.Component);
CUI.DataQueryResult.registerClass('CUI.DataQueryResult');
CUI.DataQuery.registerClass('CUI.DataQuery');
CUI.DataSource.registerClass('CUI.DataSource');
CUI.Gallery.registerClass('CUI.Gallery', CUI.Component);
CUI.Jewel.registerClass('CUI.Jewel', CUI.Root);
CUI.JewelBuildContext.registerClass('CUI.JewelBuildContext', CUI.BuildContext);
CUI.JewelBuildOptions.registerClass('CUI.JewelBuildOptions', CUI.BuildOptions);
CUI.JewelBuilder.registerClass('CUI.JewelBuilder', CUI.Builder);
CUI.MenuItem.registerClass('CUI.MenuItem', CUI.ControlComponent);
CUI.MenuLauncherControlProperties.registerClass('CUI.MenuLauncherControlProperties', CUI.ControlProperties);
CUI.BrowserUtility.registerClass('CUI.BrowserUtility');
CUI.MenuSection.registerClass('CUI.MenuSection', CUI.Component);
CUI.QAT.registerClass('CUI.QAT', CUI.Root);
CUI.QATBuildContext.registerClass('CUI.QATBuildContext', CUI.BuildContext);
CUI.QATBuildOptions.registerClass('CUI.QATBuildOptions', CUI.BuildOptions);
CUI.QATBuilder.registerClass('CUI.QATBuilder', CUI.Builder);
CUI.RibbonPeripheralSection.registerClass('CUI.RibbonPeripheralSection');
CUI.ContextualGroup.registerClass('CUI.ContextualGroup', null, Sys.IDisposable);
CUI.Template.registerClass('CUI.Template');
CUI.DeclarativeTemplate.registerClass('CUI.DeclarativeTemplate', CUI.Template);
CUI.RibbonComponent.registerClass('CUI.RibbonComponent', CUI.Component);
CUI.Group.registerClass('CUI.Group', CUI.RibbonComponent);
CUI.GroupPopup.registerClass('CUI.GroupPopup', CUI.Component);
CUI.Layout.registerClass('CUI.Layout', CUI.RibbonComponent);
CUI.GroupPopupLayout.registerClass('CUI.GroupPopupLayout', CUI.Layout);
CUI.RootEventCommandProperties.registerClass('CUI.RootEventCommandProperties');
CUI.RibbonEventCommandProperties.registerClass('CUI.RibbonEventCommandProperties', CUI.RootEventCommandProperties);
CUI.CommandContextSwitchCommandProperties.registerClass('CUI.CommandContextSwitchCommandProperties');
CUI.Ribbon.registerClass('CUI.Ribbon', CUI.Root);
CUI.RibbonCommand.registerClass('CUI.RibbonCommand');
CUI.RibbonBuildContext.registerClass('CUI.RibbonBuildContext', CUI.BuildContext);
CUI.RibbonBuildOptions.registerClass('CUI.RibbonBuildOptions', CUI.BuildOptions);
CUI.RibbonBuilder.registerClass('CUI.RibbonBuilder', CUI.Builder);
CUI.Row.registerClass('CUI.Row', CUI.Component);
CUI.ScalingStep.registerClass('CUI.ScalingStep');
CUI.Scaling.registerClass('CUI.Scaling');
CUI.Section.registerClass('CUI.Section', CUI.RibbonComponent);
CUI.Strip.registerClass('CUI.Strip', CUI.RibbonComponent);
CUI.Tab.registerClass('CUI.Tab', CUI.RibbonComponent);
CUI.TemplateManager.registerClass('CUI.TemplateManager');
CUI.RootUser.registerClass('CUI.RootUser');
CUI.ButtonDock.registerClass('CUI.ButtonDock', CUI.Component);
CUI.Toolbar.registerClass('CUI.Toolbar', CUI.Root);
CUI.ToolbarBuildContext.registerClass('CUI.ToolbarBuildContext', CUI.BuildContext);
CUI.ToolbarBuildOptions.registerClass('CUI.ToolbarBuildOptions', CUI.BuildOptions);
CUI.ToolbarBuilder.registerClass('CUI.ToolbarBuilder', CUI.Builder);
CUI.ToolTip.registerClass('CUI.ToolTip', CUI.Component);
CUI.Unit.registerClass('CUI.Unit');
CUI.Utility.registerClass('CUI.Utility');
CUI.ScriptUtility.registerClass('CUI.ScriptUtility');
CUI.UIUtility.registerClass('CUI.UIUtility');
CUI.ListNode.registerClass('CUI.ListNode');
CUI.List.registerClass('CUI.List', null, IEnumerable);
CUI.ListEnumerator.registerClass('CUI.ListEnumerator', null, IEnumerator);
CUI.JsonXmlElement.registerClass('CUI.JsonXmlElement');
CUI.Controls.ContextMenuControlProperties.registerClass('CUI.Controls.ContextMenuControlProperties', CUI.MenuLauncherControlProperties);
CUI.Controls.ContextMenuControl.registerClass('CUI.Controls.ContextMenuControl', CUI.ContextMenuLauncher);
CUI.Controls.Button.registerClass('CUI.Controls.Button', CUI.Control, CUI.IMenuItem, CUI.ISelectableControl);
CUI.Controls.CheckBoxCommandProperties.registerClass('CUI.Controls.CheckBoxCommandProperties');
CUI.Controls.ToggleButton.registerClass('CUI.Controls.ToggleButton', CUI.Control, CUI.IMenuItem, CUI.ISelectableControl);
CUI.Controls.CheckBox.registerClass('CUI.Controls.CheckBox', CUI.Controls.ToggleButton);
CUI.Controls.ColorPickerCommandProperties.registerClass('CUI.Controls.ColorPickerCommandProperties');
CUI.Controls.ColorPicker.registerClass('CUI.Controls.ColorPicker', CUI.Control, CUI.IMenuItem);
CUI.Controls.ComboBoxCommandProperties.registerClass('CUI.Controls.ComboBoxCommandProperties');
CUI.Controls.DropDown.registerClass('CUI.Controls.DropDown', CUI.MenuLauncher);
CUI.Controls.ComboBox.registerClass('CUI.Controls.ComboBox', CUI.Controls.DropDown);
CUI.Controls.DropDownCommandProperties.registerClass('CUI.Controls.DropDownCommandProperties');
CUI.Controls.FlyoutAnchor.registerClass('CUI.Controls.FlyoutAnchor', CUI.MenuLauncher);
CUI.Controls.GalleryButtonCommandProperties.registerClass('CUI.Controls.GalleryButtonCommandProperties');
CUI.Controls.GalleryButton.registerClass('CUI.Controls.GalleryButton', CUI.Control, CUI.ISelectableControl);
CUI.Controls.InsertTableCommandProperties.registerClass('CUI.Controls.InsertTableCommandProperties');
CUI.Controls.InsertTable.registerClass('CUI.Controls.InsertTable', CUI.Control);
CUI.Controls.LabelCommandProperties.registerClass('CUI.Controls.LabelCommandProperties');
CUI.Controls.Label.registerClass('CUI.Controls.Label', CUI.Control);
CUI.Controls.MRUSplitButton.registerClass('CUI.Controls.MRUSplitButton', CUI.Controls.DropDown);
CUI.Controls.Separator.registerClass('CUI.Controls.Separator', CUI.Control);
CUI.Controls.SpinnerCommandProperties.registerClass('CUI.Controls.SpinnerCommandProperties');
CUI.Controls.Spinner.registerClass('CUI.Controls.Spinner', CUI.Control);
CUI.Controls.SplitButton.registerClass('CUI.Controls.SplitButton', CUI.MenuLauncher);
CUI.Controls.TextBoxCommandProperties.registerClass('CUI.Controls.TextBoxCommandProperties');
CUI.Controls.TextBox.registerClass('CUI.Controls.TextBox', CUI.Control);
CUI.Controls.ToggleButtonCommandProperties.registerClass('CUI.Controls.ToggleButtonCommandProperties');
CUI.Controls.JewelMenuLauncher.registerClass('CUI.Controls.JewelMenuLauncher', CUI.MenuLauncher);
CUI.Page.CommandDispatcher.registerClass('CUI.Page.CommandDispatcher');
CUI.Page.FocusManager.registerClass('CUI.Page.FocusManager', CUI.Page.CommandDispatcher, CUI.Page.ICommandHandler);
CUI.Page.PageManager.registerClass('CUI.Page.PageManager', CUI.RootUser, CUI.Page.ICommandHandler, CUI.IRootBuildClient);
CUI.Page.UndoManager.registerClass('CUI.Page.UndoManager', null, CUI.Page.ICommandHandler);
Commands.CommandIds.registerClass('Commands.CommandIds');
Commands.GlobalRedoProperties.registerClass('Commands.GlobalRedoProperties');
Commands.RedoProperties.registerClass('Commands.RedoProperties');
Commands.GlobalUndoProperties.registerClass('Commands.GlobalUndoProperties');
Commands.UndoProperties.registerClass('Commands.UndoProperties');
CUI.DataNodeWrapper.ATTRIBUTES = 'attrs';
CUI.DataNodeWrapper.CHILDREN = 'children';
CUI.DataNodeWrapper.NAME = 'name';
CUI.DataNodeWrapper.ALIGNMENT = 'Alignment';
CUI.DataNodeWrapper.ALT = 'Alt';
CUI.DataNodeWrapper.CLASSNAME = 'Classname';
CUI.DataNodeWrapper.COLOR = 'Color';
CUI.DataNodeWrapper.COMMAND = 'Command';
CUI.DataNodeWrapper.CONTEXTUALGROUPID = 'ContextualGroupId';
CUI.DataNodeWrapper.CSSCLASS = 'CssClass';
CUI.DataNodeWrapper.DARKBLUE = 'DarkBlue';
CUI.DataNodeWrapper.DECIMALDIGITS = 'DecimalDigits';
CUI.DataNodeWrapper.DESCRIPTION = 'Description';
CUI.DataNodeWrapper.DISPLAYCOLOR = 'DisplayColor';
CUI.DataNodeWrapper.DISPLAYMODE = 'DisplayMode';
CUI.DataNodeWrapper.DIVIDER = 'Divider';
CUI.DataNodeWrapper.ELEMENTDIMENSIONS = 'ElementDimensions';
CUI.DataNodeWrapper.GREEN = 'Green';
CUI.DataNodeWrapper.GROUPID = 'GroupId';
CUI.DataNodeWrapper.id = 'Id';
CUI.DataNodeWrapper.INDEX = 'Index';
CUI.DataNodeWrapper.INTERVAL = 'Interval';
CUI.DataNodeWrapper.LABELTEXT = 'LabelText';
CUI.DataNodeWrapper.LAYOUTTITLE = 'LayoutTitle';
CUI.DataNodeWrapper.LIGHTBLUE = 'LightBlue';
CUI.DataNodeWrapper.LOWSCALEWARNING = 'LowScaleWarning';
CUI.DataNodeWrapper.MAGENTA = 'Magenta';
CUI.DataNodeWrapper.MAXHEIGHT = 'MaxHeight';
CUI.DataNodeWrapper.MAXIMUMVALUE = 'MaximumValue';
CUI.DataNodeWrapper.MAXWIDTH = 'MaxWidth';
CUI.DataNodeWrapper.MENUITEMID = 'MenuItemId';
CUI.DataNodeWrapper.MESSAGE = 'Message';
CUI.DataNodeWrapper.MINIMUMVALUE = 'MinimumValue';
CUI.DataNodeWrapper.namE_CAPS = 'Name';
CUI.DataNodeWrapper.ONEROW = 'OneRow';
CUI.DataNodeWrapper.ORANGE = 'Orange';
CUI.DataNodeWrapper.POPUP = 'Popup';
CUI.DataNodeWrapper.POPUPSIZE = 'PopupSize';
CUI.DataNodeWrapper.PURPLE = 'Purple';
CUI.DataNodeWrapper.SCROLLABLE = 'Scrollable';
CUI.DataNodeWrapper.SEQUENCE = 'Sequence';
CUI.DataNodeWrapper.SIZE = 'Size';
CUI.DataNodeWrapper.STYLE = 'Style';
CUI.DataNodeWrapper.TEAL = 'Teal';
CUI.DataNodeWrapper.TEMPLATEALIAS = 'TemplateAlias';
CUI.DataNodeWrapper.THREEROW = 'ThreeRow';
CUI.DataNodeWrapper.TITLE = 'Title';
CUI.DataNodeWrapper.TWOROW = 'TwoRow';
CUI.DataNodeWrapper.TYPE = 'Type';
CUI.DataNodeWrapper.VALUE = 'Value';
CUI.DataNodeWrapper.YELLOW = 'Yellow';
CUI.DataNodeWrapper.RIBBON = 'Ribbon';
CUI.DataNodeWrapper.QAT = 'QAT';
CUI.DataNodeWrapper.JEWEL = 'Jewel';
CUI.DataNodeWrapper.TABS = 'Tabs';
CUI.DataNodeWrapper.CONTEXTUALTABS = 'ContextualTabs';
CUI.DataNodeWrapper.CONTEXTUALGROUP = 'ContextualGroup';
CUI.DataNodeWrapper.TAB = 'Tab';
CUI.DataNodeWrapper.SCALING = 'Scaling';
CUI.DataNodeWrapper.MAXSIZE = 'MaxSize';
CUI.DataNodeWrapper.SCALE = 'Scale';
CUI.DataNodeWrapper.GROUP = 'Group';
CUI.DataNodeWrapper.GROUPS = 'Groups';
CUI.DataNodeWrapper.LAYOUT = 'Layout';
CUI.DataNodeWrapper.SECTION = 'Section';
CUI.DataNodeWrapper.OVERFLOWSECTION = 'OverflowSection';
CUI.DataNodeWrapper.ROW = 'Row';
CUI.DataNodeWrapper.CONTROL = 'ControlRef';
CUI.DataNodeWrapper.OVERFLOWAREA = 'OverflowArea';
CUI.DataNodeWrapper.STRIP = 'Strip';
CUI.DataNodeWrapper.CONTROLS = 'Controls';
CUI.DataNodeWrapper.MENU = 'Menu';
CUI.DataNodeWrapper.MENUSECTION = 'MenuSection';
CUI.DataNodeWrapper.TEMPLATE = 'Template';
CUI.DataNodeWrapper.TEMPLATES = 'Templates';
CUI.DataNodeWrapper.RIBBONTEMPLATES = 'RibbonTemplates';
CUI.DataNodeWrapper.GROUPTEMPLATE = 'GroupTemplate';
CUI.DataNodeWrapper.GALLERY = 'Gallery';
CUI.DataNodeWrapper.colors = 'Colors';
CUI.DataNodeWrapper.color = 'Color';
CUI.DataNodeWrapper.toggleButton = 'ToggleButton';
CUI.DataNodeWrapper.comboBox = 'ComboBox';
CUI.DataNodeWrapper.dropDown = 'DropDown';
CUI.DataNodeWrapper.button = 'Button';
CUI.DataNodeWrapper.splitButton = 'SplitButton';
CUI.DataNodeWrapper.flyoutAnchor = 'FlyoutAnchor';
CUI.DataNodeWrapper.galleryButton = 'GalleryButton';
CUI.DataNodeWrapper.insertTable = 'InsertTable';
CUI.DataNodeWrapper.label = 'Label';
CUI.DataNodeWrapper.mruSplitButton = 'MRUSplitButton';
CUI.DataNodeWrapper.spinner = 'Spinner';
CUI.DataNodeWrapper.textBox = 'TextBox';
CUI.DataNodeWrapper.checkBox = 'CheckBox';
CUI.DataNodeWrapper.colorPicker = 'ColorPicker';
CUI.DataNodeWrapper.separator = 'Separator';
CUI.DataNodeWrapper.jewelMenuLauncher = 'JewelMenuLauncher';
CUI.DataNodeWrapper.BUTTONDOCK = 'ButtonDock';
CUI.DataNodeWrapper.BUTTONDOCKS = 'ButtonDocks';
CUI.DataNodeWrapper.CENTERALIGN = 'Center';
CUI.DataNodeWrapper.LEFTALIGN = 'Left';
CUI.DataNodeWrapper.RIGHTALIGN = 'Right';
CUI.DataNodeWrapper.TOOLBAR =