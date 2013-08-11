that is currently active.</param>
      <param name="newTemplate">A <see cref="T:System.Windows.Controls.ControlTemplate" /> object that specifies a new control template to use.</param>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.OnTextChanged(System.Windows.Controls.TextChangedEventArgs)">
      <summary>Is called when content in this editing control changes.</summary>
      <param name="e">The arguments that are associated with the <see cref="E:System.Windows.Controls.Primitives.TextBoxBase.TextChanged" /> event.</param>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.OnTextInput(System.Windows.Input.TextCompositionEventArgs)">
      <summary>Invoked whenever an unhandled <see cref="E:System.Windows.Input.TextCompositionManager.TextInput" /> attached routed event reaches an element derived from this class in its route. Implement this method to add class handling for this event.</summary>
      <param name="e">Provides data about the event.</param>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.PageDown">
      <summary>Scrolls the contents of the control down by one page.</summary>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.PageLeft">
      <summary>Scrolls the contents of the control to the left by one page.</summary>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.PageRight">
      <summary>Scrolls the contents of the control to the right by one page.</summary>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.PageUp">
      <summary>Scrolls the contents of the control up by one page.</summary>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.Paste">
      <summary>Pastes the contents of the Clipboard over the current selection in the text editing control.</summary>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.Redo">
      <summary>Undoes the most recent undo command. In other words, redoes the most recent undo unit on the undo stack.</summary>
      <returns>true if the redo operation was successful; otherwise, false. This method returns false if there is no undo command available (the undo stack is empty).</returns>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.ScrollToEnd">
      <summary>Scrolls the view of the editing control to the end of the content.</summary>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.ScrollToHome">
      <summary>Scrolls the view of the editing control to the beginning of the viewport.</summary>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.ScrollToHorizontalOffset(System.Double)">
      <summary>Scrolls the contents of the editing control to the specified horizontal offset.</summary>
      <param name="offset">A double value that specifies the horizontal offset to scroll to.</param>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.ScrollToVerticalOffset(System.Double)">
      <summary>Scrolls the contents of the editing control to the specified vertical offset.</summary>
      <param name="offset">A double value that specifies the vertical offset to scroll to.</param>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.SelectAll">
      <summary>Selects all the contents of the text editing control.</summary>
    </member>
    <member name="P:System.Windows.Controls.Primitives.TextBoxBase.SelectionBrush">
      <summary>Gets or sets the brush that highlights selected text.</summary>
      <returns>The brush that highlights selected text.</returns>
    </member>
    <member name="F:System.Windows.Controls.Primitives.TextBoxBase.SelectionBrushProperty">
      <summary>Identifies the <see cref="P:System.Windows.Controls.Primitives.TextBoxBase.SelectionBrush" /> dependency property.</summary>
    </member>
    <member name="E:System.Windows.Controls.Primitives.TextBoxBase.SelectionChanged">
      <summary>Occurs when the text selection has changed.</summary>
    </member>
    <member name="F:System.Windows.Controls.Primitives.TextBoxBase.SelectionChangedEvent">
      <summary>Identifies the <see cref="E:System.Windows.Controls.Primitives.TextBoxBase.SelectionChanged" /> routed event. </summary>
      <returns>The identifier for the <see cref="E:System.Windows.Controls.Primitives.TextBoxBase.SelectionChanged" /> routed event.</returns>
    </member>
    <member name="P:System.Windows.Controls.Primitives.TextBoxBase.SelectionOpacity">
      <summary>Gets or sets the opacity of the <see cref="P:System.Windows.Controls.Primitives.TextBoxBase.SelectionBrush" />.</summary>
      <returns>The opacity of the <see cref="P:System.Windows.Controls.Primitives.TextBoxBase.SelectionBrush" />. The default is 0.4.</returns>
    </member>
    <member name="F:System.Windows.Controls.Primitives.TextBoxBase.SelectionOpacityProperty">
      <summary>Identifies the <see cref="P:System.Windows.Controls.Primitives.TextBoxBase.SelectionOpacity" /> dependency property.</summary>
    </member>
    <member name="P:System.Windows.Controls.Primitives.TextBoxBase.SpellCheck">
      <summary>Gets a <see cref="T:System.Windows.Controls.SpellCheck" /> object that provides access to spelling errors in the text contents of a <see cref="T:System.Windows.Controls.Primitives.TextBoxBase" /> or <see cref="T:System.Windows.Controls.RichTextBox" />.</summary>
      <returns>A <see cref="T:System.Windows.Controls.SpellCheck" /> object that provides access to spelling errors in the text contents of a <see cref="T:System.Windows.Controls.Primitives.TextBoxBase" /> or <see cref="T:System.Windows.Controls.RichTextBox" />.This property has no default value.</returns>
    </member>
    <member name="E:System.Windows.Controls.Primitives.TextBoxBase.TextChanged">
      <summary>Occurs when content changes in the text element.</summary>
    </member>
    <member name="F:System.Windows.Controls.Primitives.TextBoxBase.TextChangedEvent">
      <summary> Identifies the <see cref="E:System.Windows.Controls.Primitives.TextBoxBase.TextChanged" /> routed event. </summary>
      <returns>The identifier for the <see cref="E:System.Windows.Controls.Primitives.TextBoxBase.TextChanged" /> routed event.</returns>
    </member>
    <member name="M:System.Windows.Controls.Primitives.TextBoxBase.Undo">
      <summary>Undoes the most recent undo command. In other words, undoes the most recent undo unit on the undo stack.</summary>
      <returns>true if the undo operation was successful; otherwise, false. This method returns false if the undo stack is empty.</returns>
    </member>
    <member name="P:System.Windows.Controls.Primitives.TextBoxBase.UndoLimit">
      <summary>Gets or sets the number of actions stored in the undo queue.</summary>
      <returns>The number of actions stored in the undo queue. The default is –1, which means the undo queue is limited to the memory that is available.</returns>
      <exception cref="T:System.InvalidOperationException">
        <see cref="P:System.Windows.Controls.Primitives.TextBoxBase.UndoLimit" /> is set after calling <see cref="M:System.Windows.Controls.Primitives.TextBoxBase.BeginChange" /> and before calling <see cref="M:System.Windows.Controls.Primitives.TextBoxBase.EndChange" />.</exception>
    </member>
    <member name="F:System.Windows.Controls.Primitives.TextBoxBase.U