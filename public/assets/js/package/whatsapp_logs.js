$(document).ready(function () {

  // Enhanced listing table. DB already returns newest-first, so keep that order
  // (order: []) and just layer search / paging on top. Message and action
  // columns hold markup, not sortable data.
  if ($("#whatsapp_logs_table").length) {
    $("#whatsapp_logs_table").DataTable({
      order: [],
      pageLength: 25,
      lengthMenu: [10, 25, 50, 100],
      columnDefs: [
        { orderable: false, targets: [2, 8] }
      ],
      language: {
        search: "",
        searchPlaceholder: "Quick search…",
        emptyTable: "No WhatsApp messages logged yet."
      }
    });
  }

  // View → clone the row's hidden detail block into the modal and show it.
  $(document).on("click", ".wa-view-btn", function () {
    var detailId = $(this).data("target-detail");
    var html = $("#" + detailId).html();
    $("#waModalBody").html(html);
    var modalEl = document.getElementById("waDetailModal");
    var modal = bootstrap.Modal.getOrCreateInstance(modalEl);
    modal.show();
  });
});

// Submit the filter form to the search action (mirrors Member Subscriptions).
function filter_whatsapp_logs() {
  var useroot = $("#rootXPath").val();
  $(".show_loader").removeClass("hidden");
  $(".no_loader").addClass("hidden");
  $("form#myForms").attr("action", useroot + "whatsapp_logs/search");
  $("form#myForms").submit();
}

// Enter key in the search box triggers the same filter.
$(document).on("keypress", "#log_search", function (e) {
  var keycode = e.keyCode ? e.keyCode : e.which;
  if (keycode == 13) {
    e.preventDefault();
    filter_whatsapp_logs();
  }
});
