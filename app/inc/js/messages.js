// File: app/inc/js/messages.js
// Desc: messages

'use strict';

var messages = {
    $container: util.element('div#messages'),

    confirm: function(message_class, button_class, button_text, message, callback) {
        var $element = util.build('div')
                        .addClass('message')
                        .addClass(message_class)
                        .append(message + ' '),
                $button = $element.build('button')
                            .addClass(button_class)
                            .append(button_text);
        $element.build('span')
            .append(' or ');
        var $cancel = $element.build('a')
                        .append('Cancel'),
            self = this;

        $button.addEventListener('click', callback);
        $cancel.addEventListener('click', function() {
            self.$container.removeChild($element);
        });
        this.$container.appendChild($element);
    }
};

window.addEventListener('load', function() {
    util.each(util.elements('div#messages div.message'), function(key, $message) {
        $message.addEventListener('click', function() {
            this.parentNode.removeChild(this);
        });
    });
});