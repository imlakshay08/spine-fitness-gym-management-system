function get_defaulter_list(reqtype, course, sem) {
    var usePath = $.trim($("#rootXPath").val());

    var labelText = "";
    switch (reqtype) {
        case "PS":
            labelText = "List of Paid Students";
            break;
        case "DF":
            labelText = "List of Defaulter Students";
            break;
        default:
            labelText = "List of Students";
    }

    $("#reqtype_label").text(labelText); //

    // Show the loader
    $(".process_loader_table").show();

    $.ajax({
        url: usePath + "fee_dashboard/ajax_process",
        type: 'POST',
        data: { 'identity': 'VIEWDEFAULTER', 'reqtype':reqtype, 'course': course, 'sem': sem },
        success: function (resp) {
            if (resp.status) {
                $("#defaulters_list").html(resp.data);
                  // Show Excel button row
                  $("#excel_button_row").show();
            } else {
                alert("No record(s) found.");
                // Hide Excel button row if no data
                 $("#excel_button_row").hide();
            }
        },
        error: function () {
            alert("An error occurred while processing the request.");
        },
        complete: function () {
            // Hide the loader when done
            $(".process_loader_table").hide();
        },
        cache: false
    });
}

function filter_fee_summary(){
    var useroot = $("#rootXPath").val();
    var finYear = $("#financial_years").val();

    if (!finYear || finYear.trim() === "") {
        alert("Please select a Financial Year.");
        $("#financial_years").focus();
        return false;
    }

    $(".show_loader").removeClass("hidden");
    $(".no_loader").removeClass("hidden").addClass("hidden")
    $("#myForms").attr("action",useroot+"fee_dashboard/search");
    $("#myForms").submit();
}

function exportStyledExcel() {
    var table = document.getElementById("student_table");
    var label = $("#reqtype_label").text();
    var filename = label.replace(/\s+/g, '_') + ".xlsx"; // eg. "Hostel_Fee_Defaulter_List.xlsx"

    // Convert HTML table to worksheet
    var ws = XLSX.utils.table_to_sheet(table, { raw: true });

    // Apply border to all used cells
    const range = XLSX.utils.decode_range(ws['!ref']);
    for (let R = range.s.r; R <= range.e.r; ++R) {
        for (let C = range.s.c; C <= range.e.c; ++C) {
            const cell_ref = XLSX.utils.encode_cell({ c: C, r: R });
            if (!ws[cell_ref]) continue;

            ws[cell_ref].s = ws[cell_ref].s || {};
            ws[cell_ref].s.border = {
                top:    { style: "thin", color: { rgb: "000000" } },
                bottom: { style: "thin", color: { rgb: "000000" } },
                left:   { style: "thin", color: { rgb: "000000" } },
                right:  { style: "thin", color: { rgb: "000000" } }
            };
        }
    }

    // Create workbook and export
    var wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "sheet1");

    // Export using actual filename
    XLSX.writeFile(wb, filename);
}
