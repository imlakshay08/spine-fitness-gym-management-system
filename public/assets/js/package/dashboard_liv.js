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

/* ---- Collect Payment modal (dashboard due-members list) ---- */
function openCollectPayment(subId, dueAmount, memberName){
  document.getElementById('cp_subscription_id').value = subId;
  document.getElementById('cp_amount').value = dueAmount;
  document.getElementById('cp_member_label').textContent = memberName || "";
  var btn = document.getElementById('cp_save_btn');
  btn.disabled = false; btn.textContent = "Save Payment";
  document.getElementById('collectPaymentModal').style.display = 'block';
}
function closeCollectPayment(){
  document.getElementById('collectPaymentModal').style.display = 'none';
}
function submitCollectPayment(){
  var usePath = $.trim($("#rootXPath").val());
  var amount  = $.trim($("#cp_amount").val());
  if (amount === "" || parseFloat(amount) <= 0){ alert("Enter a valid amount."); return; }

  var $btn = $("#cp_save_btn");
  $btn.prop("disabled", true).text("Saving...");

  $.ajax({
    url: usePath + "member_subscriptions/ajax_process",
    type: "POST",
    dataType: "json",
    data: {
      identity: "COLLECTPAY",
      subscription_id: $("#cp_subscription_id").val(),
      pay_amount: amount,
      pay_mode: $("#cp_mode").val(),
      pay_date: $.trim($("#cp_date").val()),
      pay_remarks: $.trim($("#cp_remarks").val())
    },
    success: function(resp){
      if (resp.status){ location.reload(); }
      else { alert(resp.message); $btn.prop("disabled", false).text("Save Payment"); }
    },
    error: function(){ alert("Error saving payment. Please try again."); $btn.prop("disabled", false).text("Save Payment"); }
  });
}