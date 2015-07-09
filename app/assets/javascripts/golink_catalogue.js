/** 
* MODAL STUFF
*/
function pullModalContentActions(){
  $('.link-modal').click(function(){
    id = $(this).attr('id');
    hidden_info = $(this).find('.hidden-edit-info').html();
    //change modal content
    $('#edit-modal-content').html(hidden_info);
    $('#myModalLabel').html($(this).find('.hidden-edit-info').attr('id'));
  });
}
function updateLinkActions(){
  $("#save-link-btn").click(function(){
  var id = $('#edit-modal-content').find("#go-id-input").val();
  url = $('#edit-modal-content').find("#go-url-input").val();
  description = $('#edit-modal-content').find("#go-description-input").val();
  directory = $('#edit-modal-content').find('#go-directory-input').val();
  console.log(url);
  console.log(description);
  console.log(directory);
  console.log(id);
  $.ajax({
      url: '/go/' + id + '/update',
      type: 'POST',
      data: {'url': url ,'description': description, 'directory': directory},
      success:function(data){
        location.reload();
      },
      error:function (xhr, textStatus, thrownError){
        alert('Failed');
      }
    });
});
}
function deleteLinkActions(){
   $("#delete-link-btn").click(function(){
  var id = $('#edit-modal-content').find("#go-id-input").val();
  window.location.replace("/go/"+id+"/destroy");
  // window.location = 
}); 
}

function clipboardCopyActions(){
  $('.clipboard-copy').click(function(event){
    event.preventDefault();
    id = $(this).attr('id');
    window.prompt("Copy to clipboard: Ctrl+C, Enter", id);
  }             
);
}

function directoryLinkScrollActions(){
	$('.directory-link').click(function(event){
	    event.preventDefault();
	    id = $(this).attr('href');
	    console.log(id);
	    // $(this).next('div').slideToggle(200);
	    $('html, body').animate({
	        scrollTop: ($(id).offset().top - 100)
	    }, 200);
	  }             
	);
}
function favoriteLinkActions(){
	$('.favorite-link').click(function(event){
		event.preventDefault();
		key = $(this).attr('id');
		member_email = email;
		
		if($(this).hasClass("mdi-action-favorite-outline")){
			status = 'favorite';
		}
		else{
			status = 'unfavorite';
		}
		console.log(key);
		console.log(member_email);
		console.log(status);
		that = $(this);
		$.ajax({
	      url: '/go/favorite',
	      type: 'GET',
	      data: {'email': member_email ,'key': key, 'status': status},
	      success:function(data){
	        //switch classes for favorite icon
	        // alert('done'); 
	        if($(that).hasClass('mdi-action-favorite-outline')){
	        	$(that).removeClass('mdi-action-favorite-outline');
	        	$(that).addClass('mdi-action-favorite');
	        }
	        else{
	        	$(that).removeClass('mdi-action-favorite');
	        	$(that).addClass('mdi-action-favorite-outline');
	        }
	      },
	      error:function (xhr, textStatus, thrownError){
	        alert('Failed');
	      }
	    });
	});
}

$(document).ready(function(){
	directoryLinkScrollActions();
	  pullModalContentActions();
	  updateLinkActions();
	  deleteLinkActions();
	  
	  clipboardCopyActions();
	  favoriteLinkActions();
});
	