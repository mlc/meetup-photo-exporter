$(function() {
    $(".gallery .photo a").lightBox({fixedNavigation: true});
    $(".close-me").click(function() {
        $(this).closest(".sysmsg").hide();
    })
});