script "DataView Pagination Controller Behavior" with behavior "DataView Array Controller Behavior"

local sLocalsA

/**
Summary: Stores certain properties required for this behavior.

Parameters:
pProp: The property to set.
pValue: The value to assign to the property.

Description:
Pagination requires knowledge of how many pages there are total as well
as how many results are on each page. Set the `number of rows` property
as well as the `rows per page` property to store this information.

Returns: nothing
*/
setProp viewProp[pProp] pValue
  if pProp is "number of rows" then
    put pValue into sLocalsA["number of rows"]
  else if pProp is "rows per page" then
    put pValue into sLocalsA["rows per page"]
  else
    pass viewProp
  end if
end viewProp


/**
Summary: Returns properties stored or synthesized by this behavior.

Returns: nothing
*/
getProp viewProp[pProp]
  switch pProp
    case "number of pages"
      return ceiling(sLocalsA["number of rows"] / sLocalsA["rows per page"])
      break

    case "number of rows"
    case "rows per page"
      return sLocalsA[pProp]

    default
      pass viewProp
      break
  end switch
end viewProp


/**
Summary: Looks for pages that need to be loaded.

Parameters:
pRow: See DataView docs.
rDataA: See DataView docs.
rTemplateStyle: See DataView docs.

Description:
This hanlder inspects `rData` to see if the `id` property is empty. If it
is then the page of results that `pRow` is associated with is requested by
sending the `LoadDataForPage` message.

Returns: nothing
*/
after DataForRow pRow, @rDataA, @rTemplateStyle
  if rDataA["id"] is empty then
    _AddCurrentPageOfDataToQueue pRow
    _StartRequestingPages
  end if
end DataForRow


/**
Summary: Returns the stored number of rows.

Returns: Integer
*/
function NumberOfRows
  return sLocalsA["number of rows"]
end NumberOfRows


/**
Summary: Adds data to a page in the DataView's data source.

Description:
This will be called after `LoadDataForPage` is processed by the data provider
and there are records to insert into the page.

Returns: nothing
*/
setProp dvDataForPage[pPage] pDataA
  local tRow, i

  put ((pPage-1) * sLocalsA["rows per page"]) into tRow

  repeat with i = 1 to the number of elements of pDataA
    add 1 to tRow
    set the dvRowData[tRow] of me to pDataA[i]
  end repeat
end dvDataForPage


/**
Summary: Starts downloading pages in the queue if a request is not already running.

Returns: nothing
*/
private command _StartRequestingPages
  if sLocalsA["waiting on page"] is empty then
    _RequestNextPageInQueue
  end if

  return empty
end _StartRequestingPages


/**
Summary: Adds the current page that is visible in the DataView to the queue of pages to load.

Description:
When the DataView scrolls to a record that has no `id` the page that the
row is on is added to a queue of pages whose data needs to be requested. The page
passed in will be placed at the front of the queue as it is currently
visible to the user.

Returns: nothing
*/
private command _AddCurrentPageOfDataToQueue pRowWithMissingId
  local tPageToLoad, tItemNo

  set the wholematches to true

  put (pRowWithMissingId + (sLocalsA["rows per page"]-1)) \
        div sLocalsA["rows per page"] into tPageToLoad

  # Add tPageToLoad to front of pages to load.
  put itemoffset(tPageToLoad, sLocalsA["page queue"]) into tItemNo
  if tItemNo is not empty then
    delete item tItemNo of sLocalsA["page queue"]
  end if

  if sLocalsA["page queue"] is not empty then
    put tPageToLoad & "," before sLocalsA["page queue"]
  else
    put tPageToLoad into sLocalsA["page queue"]
  end if

  return empty
end _AddCurrentPageOfDataToQueue


/**
Summary: Dispatches the `LoadDataForPage` message for the next page in the queue.

Returns: nothing
*/
private command _RequestNextPageInQueue
  local tLoadPage

  if sLocalsA["waiting on page"] is empty and sLocalsA["page queue"] is not empty then
    put item 1 of sLocalsA["page queue"] into tLoadPage
    delete item 1 of sLocalsA["page queue"]

    put tLoadPage into sLocalsA["waiting on page"]
    dispatch "LoadDataForPage" with tLoadPage
  end if

  return empty
end _RequestNextPageInQueue
