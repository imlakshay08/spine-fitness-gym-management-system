$(document).ready(function() {
  $('#filter_user').select2({
    placeholder: "-Select-",
    allowClear: true,
    width: 'resolve'
  });

  $('#filter_user').on('select2:open', function () {
    $('.select2-search__field').focus();
  });

  $('#filter_user').on('change', function() {
    $('#myForms').submit();

  });
});

var lastChecked = null;
var usePath = $.trim($("#rootXPath").val());

function fetchLiveAttendance() {
  var formData = new FormData();
  formData.append("identity", "GET_LIVE_ATTENDANCE");
  formData.append("server_request", "Y");
  // Remove the lastChecked/since logic entirely

  $.ajax({
    url: usePath + "dashboard/ajax_process",
    type: "POST",
    data: formData,
    async: true,
    contentType: false,
    processData: false,
    success: function(resp) {
      // Always update timestamp
      if (resp.last_checked) {
        lastChecked = resp.last_checked;
        $("#last-updated").text("Updated: " + new Date().toLocaleTimeString());
      }

      if (resp.status && resp.data.length > 0) {
        var tbody = $("#live-attendance-body");
        tbody.empty();

        resp.data.forEach(function(row) {
          var accessClass = row.att_status === "ALLOWED" ? "text-success" : "text-danger";
          var accessIcon  = row.att_status === "ALLOWED" ? "✓" : "✗";
          var subClass    = row.sub_status === "Active"  ? "text-success" : "text-danger";
          var rowClass    = row.att_status === "ALLOWED" ? "" : "table-danger";

          var tr = '<tr class="' + rowClass + '">' +
            '<td><strong>' + row.member_name + '</strong></td>' +
            '<td>' + row.punch_time + '</td>' +
            '<td class="' + subClass + '">' + row.sub_status + '</td>' +
            '<td class="' + accessClass + '"><strong>' + accessIcon + ' ' + row.att_status + '</strong></td>' +
            '</tr>';
          tbody.append(tr);
        });
      }
    },
    error: function() {
      console.log("Live attendance fetch failed");
    },
    cache: false
  });
}

$(document).ready(function() {
  fetchLiveAttendance();
  setInterval(fetchLiveAttendance, 5000);
});