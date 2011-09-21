var currentcoords = "";
var curZI = 2;
function loadImmediate()
{
	location.hash = currentcoords;
	
	for(var i = 1; i <= 4; i++)
	{
		var ccoords = currentcoords + i;
		$('.viewport').append(
			$('<img class="quad' + i + '" quad="' + i + '" src="res/' + ccoords + '.jpg" />')
			.css('width', '300px')
			.css('height', '300px')
			.css('cursor', 'pointer')
			.click(function(){zoomIn(this.getAttribute('quad'))})
			);
		for(var ii = 1; ii <= 4; ii++)
		{
			var img = new Image();
			img.src = currentcoords + i + "" + ii + ".jpg";
		}
	}
}
function zoomIn(quadrant)
{		
	currentcoords = currentcoords + quadrant;
			
	var el = $('.quad' + quadrant);
	el.css('z-index', 2)
		.animate(
			{
				width:'+=300',
				height:'+=300'
			},
			{
				duration:250,
				complete:function() {
					$(this)
					.animate(
						{
							opacity:0
						},
						{
							duration:500,
							complete:function(){$(this).remove()}
						});
				}
			});
	$('.viewport')
		.css('background-image', 'url(' + $('.quad' + quadrant).attr('src') + ')');
	$('.viewport')
		.children()
		.not(el)
		.remove();
	loadImmediate();
}
function zoomOut()
{
	if(currentcoords.length < 1)
		return;
		
	var prevquad = currentcoords.substr(currentcoords.length-1);
	currentcoords = currentcoords.substr(0, currentcoords.length-1);
	
	$('.viewport')
		.children()
		.remove();
	
	loadImmediate();
	
	$('.quad' + prevquad)
		.css('width', '600px')
		.css('height', '600px');

	$('.quad' + prevquad)
		.css('z-index', 2)
		.animate(
			{
				width:'-=300',
				height:'-=300'
			},
			{
				duration:250
			});
	return false;
}
window.onload = function()
{
	if(location.hash[0] == '#')
		currentcoords = location.hash.substr(1);
		
	loadImmediate();
	$('.zoomout').click(zoomOut);
}