# DataView Pagination Helper

The DataView Pagination helper extends the `DataView Array Controller Behavior` included with the [DataView Helper](https://github.com/trevordevore/levurehelper-dataview) to support the display of paginated results. Pages of results are often returned by APIs that may potentially return large amounts of data. That data must be requested in pages so the data will not all be available when the DataView is asked to display the first page of results.

## Demo

The DataView Demo application includes an example of using this helper:

https://github.com/trevordevore/dataview_demo

The example below is taken from the "Pokemon" tab in the demo application.

## Usage

### Step 1

Set the `viewProp["magic key"]` custom property of the DataView. This property is the name of a key in a row's data array that will be checked for an empty value. If the value is empty then the DataView assumes the page of results for that row has not been fetched yet and the `LoadDataForPage` message will be dispatched. For the example in step 2 the `magic key` is `name` so you would assign `name` to the custom property as follows: 

```
set the viewProp["magic key"] of group "Pokemon" to "name"
```

This property is saved with the DataView when you save your stack.

### Step 2

Define the `LoadDataForPage` handler in your script (e.g. a card script). This handler is responsible for starting an asynchronous download of data from an API that uses pagination.

When that data has finished loading the data is added to the DataView by doing the following:

1. Setting the `viewProp["number of rows"]` and `viewProp["rows per page"] `properies if they are not up to date.
2. Setting the `dvDataForPage` custom property of the DataView with the new data.

Here is an example that uses the `pokeapi.co` website (error checking removed). The DataView is named "Pokemon".

```
constant kNumberPerPage = 20
local sPageThatIsLoading

command LoadDataForPage pPage
  local tOffset

  put pPage into sPageThatIsLoading
  put (pPage-1) * kNumberPerPage into tOffset

  load url "https://pokeapi.co/api/v2/pokemon?offset=" & tOffset & "&limit=" & kNumberPerPage with message "ReceiveDataForPage"
end LoadDataForPage


command ReceiveDataForPage pUrl, pUrlStatus
  put URL pUrl into tResponseA
  if tResponseA is not empty then
    put JsonImport(tResponseA) into tResponseA
  end if
  unload URL pUrl

  if tResponseA["count"] is not the viewProp["number of rows"] of group "Pokemon" then
    set the dvData of group "Pokemon" to empty

    # Important! Set these properties AFTER setting the dvData to empty.
    set the viewProp["number of rows"] of group "Pokemon" to tResponseA["count"]
    set the viewProp["rows per page"] of group "Pokemon" to kNumberPerPage
  end if

  set the dvDataForPage[sPageThatIsLoading] of group "Pokemon" to tResponseA["results"]
end ReceiveDataForPage


on closeCard
  dispatch "ResetView" to group "Pokemon"
end closeCard
```

### Step 3

Call `LoadDataForPage 1` to load the first page of results into the DataView. When the user scrolls the DataView the `LoadDataForPage` message will be dispatched each time a row is encountered which has an empty value for the `magic key` key in the row's data array.

### Step 4

When you have finished using the DataView dispatch "ResetView" to it (e.g. in `closeCard`). This will reset the `number of rows` and `rows per page` properties.
