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
