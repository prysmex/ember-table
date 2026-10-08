export interface EmberTableColumn {
  name?: string;
  valuePath?: string;

  isFixed?: 'left' | 'right';
  isResizable?: boolean;
  isSortable?: boolean;
  maxWidth?: number;
  minWidth?: number;
  subcolumns?: EmberTableColumn[];
  textAlign?: 'left' | 'center' | 'right';
  width?: number;
}

// Extension point: applications describe their rows by extending this.
// eslint-disable-next-line @typescript-eslint/no-empty-object-type
export interface EmberTableRow {}

export interface EmberTableSort {
  isAscending: boolean;
  valuePath: string;
}

export interface TableRowMeta {
  index: number;
  isCollapsed: boolean;
  isSelected: boolean;
  isGroupSelected: boolean;
  canCollapse: boolean;
  depth: number;
  first: unknown;
  last: unknown;
  next: unknown;
  prev: unknown;
}

export interface TableColumnMeta {
  isLeaf: boolean;
  isFixed: 'left' | 'right' | undefined;
  isSortable: boolean;
  isResizable: boolean;
  isResizing: boolean;
  isReorderable: boolean;
  isSlack: boolean;
  width: number;
  offsetLeft: number;
  offsetRight: number;
  rowSpan: number;
  columnSpan: number;
  index: number | undefined;
  isLastRendered: boolean;
  sortIndex: number;
  isSorted: boolean;
  isMultiSorted: boolean;
  isSortedAsc: boolean;
}

/**
  The value of a cell in a row of `RowType`. Templates usually cannot infer the
  row type (rows are passed to the body, not the table), so rows without known
  keys yield an untyped value instead of `never`.
*/
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type CellValue<RowType> = [keyof RowType] extends [never] ? any : RowType[keyof RowType];
