New-UIWidget -AsJob -Content {
	$shadow = DropShadowEffect -Color Black -Shadow 0 -Blur 8
	$now = Get-Date;
	StackPanel {
		TextBlock -Name "Time" ('{0:h:mm tt}' -f $now) -FontSize 108 -LineHeight 100 -LineStackingStrategy BlockLineHeight -Margin 0 -Padding 0 -Foreground White -Effect $shadow -FontFamily "Century Gothic"
		StackPanel -Orientation Horizontal {
			TextBlock -Name "Day" ('{0:dd}' -f $now) -FontSize 80 -LineHeight 80 -LineStackingStrategy BlockLineHeight -Margin 0 -Padding 0 -Foreground White -Opacity 0.6 -Effect $shadow -FontFamily "Century Gothic"
			StackPanel {
				TextBlock -Name "Month" ('{0:MMMM}' -f $now).ToUpper() -fontsize 40 -LineHeight 40 -LineStackingStrategy BlockLineHeight -Margin 0 -Padding 0 -FontFamily "Century Gothic"
				TextBlock -Name "Weekday" ('{0:dddd}' -f $now).ToUpper() -fontsize 28 -LineHeight 28 -LineStackingStrategy BlockLineHeight -Margin 0 -Padding 0 -Foreground White -Effect $shadow -FontFamily "Century Gothic"
			} -Margin 0
		} -Margin 0
	} -Margin 0
} -Interval "0:0:0.2" -UpdateBlock {
	$now = Get-Date

	$Time.Text = '{0:h:mm tt}' -f $now
	$Day.Text = '{0:dd}' -f $now
	$Month.Text = ('{0:MMMM}' -f $now).ToUpper()
	$Weekday.Text = ('{0:dddd}' -f $now).ToUpper()
}