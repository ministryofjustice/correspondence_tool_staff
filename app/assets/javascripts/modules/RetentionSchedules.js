moj.Modules.RetentionSchedules = {
    $select_all_checkbox: $("#retention-select-all-checkbox"),

    init: function() {
        var self = this;
        self.$select_all_checkbox.change(function () {
            $("input:checkbox").prop('checked', $(this).prop("checked"));
        });
    },
};
