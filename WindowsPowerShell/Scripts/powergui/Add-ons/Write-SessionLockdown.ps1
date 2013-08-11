 {
            return false;
        }
        if (!($v_0).get_$1F()) {
            (this).receiveFocus();
            return true;
        }
        return false;
    },
    
    $C7: function() {
    },
    
    $5p: function() {ULSpEN:;
        var $v_0 = this.get_displayedComponent();
        if (CUI.ScriptUtility.isNullOrUndefined($v_0)) {
            return null;
        }
        return $v_0.get_$2();
    },
    
    $7o: function() {ULSpEN:;
        return false;
    }
}


CUI.ControlComponent = function(root, id, displayMode, control) {ULSpEN:;
    CUI.ControlComponent.initializeBase(this, [ root, id, displayMode, '' ]);
    this.$M_1 = control;
}
CUI.ControlComponent.prototype = {
    $M_1: null,
    
    get_displayMode: function() {ULSpEN:;
        return this.get_title();
    },
    
    createChildArray: function() {
    },
    
    $L: function() {ULSpEN:;
        this.$g_0 = false;
    },
    
    $3v: function() {ULSpEN:;
        this.$M_1.$35(this.get_displayMode());
    },
    
    $N: function() {ULSpEN:;
        this.$M_1.$O(this.get_displayMode());
    },
    
    get_$2: function() {ULSpEN:;
        return this.$M_1.getDOMElementForDisplayMode(this.get_title());
    },
    set_$2: function($p0) {
        throw Error.create('Cannot set the DOM Element of ControlComponents.  They get their DOM Elements from the Control.');
        return $p0;
    },
    
    get_componentElement: function() {ULSpEN:;
        return CUI.ControlComponent.callBaseMethod(this, 'get_$2');
    },
    
    ge