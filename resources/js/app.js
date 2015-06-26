$(function() {

	$.ajaxSettings.traditional = true;

	$('a.papyri-facet').on('click', function(e) {
		e.preventDefault();
		$(this).toggleClass('papyri-facet-active');

		request = {};
		$('ul.papyri-facets').each(function(){
			facet = $(this).attr('data-papyri-facet');
			values = $.map($(this).children('li').children('.papyri-facet'), function(elem, i) {
				return $(elem).hasClass("papyri-facet-active") ? $(elem).attr('data-papyri-facet-value') : null;
			});
			request[facet] = values;
		});

		$('#papyri-results').load('query', $.param(request));
		
	});

  searchForm = $('form.papyri-complex-search')
  searchFields = $(searchForm).children('.search-fields');

  getField = function(name, index, callback) {
    $.ajax({
      url: papyri_app_root + '/search-field',
      data: {
        name: name,
        index: index
      },
      dataType: 'html',
      success: function(data) {
        callback(data);
      }

    });
  }

  $(searchFields).on('change', 'select.field', function(e) {

    parentFieldset = $(this).parents("fieldset");

    getField(
      $(this).children('option:selected').attr('value'), 
      $(parentFieldset).index() + 1, 
      function(field) {
        $(parentFieldset).replaceWith($(field));
      }
    );
  });

  $(searchForm).find('#add').on('click', function(e) {
    e.preventDefault();
    fields = $(searchFields).children('fieldset');
    console.log(fields);
    lastField = $(fields).last();
    getField(
      'material',
      fields.length + 1,
      function(field) {
        $(field).insertAfter(lastField);
      }
    );
  });

  $(searchFields).on('click', '.add-or', function(e) {
    e.preventDefault();
    parentFieldset = $(this).parents("fieldset");
    termField = $(parentFieldset).find('.term').first();

    orRow = $('<div class="row-fluid or"></div>');
    orCol = $('<div class="span5"></div>')
      .append($(termField).clone())
      .append('&#160;<a href="#" class="remove-or">&#160;–&#160;</a>');

    orRow
      .append('<div class="span6">&#160;</div>')
      .append('<div class="span1 or">oder</div>')
      .append(orCol)
      .appendTo(parentFieldset);    
    
  });

  $(searchFields).on('click', '.remove', function(e) {
    e.preventDefault();
    parentFieldset = $(this).parents("fieldset");
    parentFieldset.remove();
  });

    $(searchFields).on('click', '.remove-or', function(e) {
    e.preventDefault();
    parentOrRow = $(this).parents(".or");
    parentOrRow.remove();
  });

});