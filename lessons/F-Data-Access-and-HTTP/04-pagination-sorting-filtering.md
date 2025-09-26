# Lesson 4: Pagination, Sorting, and Filtering

Displaying large datasets requires a way for users to navigate and refine the data. Implementing pagination, sorting, and filtering is a fundamental requirement for most data-driven applications. A reactive approach using RxJS provides a powerful and elegant way to handle the complex state interactions involved.

The core pattern is to treat each user-driven change (changing the page, sorting a column, applying a filter) as an observable stream. We then combine these streams to trigger a single, consolidated data request to the API.

## 1. Modeling the State as Streams

First, we need to create streams that represent the current state of our list's parameters. We can do this in a service or a component that manages the list. `BehaviorSubject` is a good choice because it holds the current value for new subscribers.

```typescript
// products.service.ts
import { BehaviorSubject } from 'rxjs';

// --- State Subjects ---
// Pagination
private page$ = new BehaviorSubject<number>(1);
private pageSize$ = new BehaviorSubject<number>(10);

// Sorting
private sortColumn$ = new BehaviorSubject<string>('name');
private sortDirection$ = new BehaviorSubject<'asc' | 'desc'>('asc');

// Filtering
private filterQuery$ = new BehaviorSubject<string>('');

// --- Public Actions ---
// Methods to allow the UI to change the state
changePage(page: number) { this.page$.next(page); }
changePageSize(pageSize: number) { this.pageSize$.next(pageSize); }
changeSort(column: string) {
  const currentSort = this.sortColumn$.value;
  if (column === currentSort) {
    // Flip direction if same column is sorted again
    this.sortDirection$.next(this.sortDirection$.value === 'asc' ? 'desc' : 'asc');
  } else {
    // Reset to ascending on new column
    this.sortColumn$.next(column);
    this.sortDirection$.next('asc');
  }
}
applyFilter(query: string) { this.filterQuery$.next(query); }
```

## 2. Combining State Streams

Now that we have streams for each parameter, we can use `combineLatest` to merge them into a single stream of request parameters. We also use `debounceTime` on the filter to avoid sending requests on every keystroke.

```typescript
// products.service.ts (continued)
import { combineLatest, Observable } from 'rxjs';
import { debounceTime, map, distinctUntilChanged } from 'rxjs/operators';

// Interface for the combined parameters
export interface ProductRequestParams {
  page: number;
  pageSize: number;
  sortColumn: string;
  sortDirection: 'asc' | 'desc';
  filter: string;
}

// Combine all state streams into a single parameters stream
private params$: Observable<ProductRequestParams> = combineLatest([
  this.page$,
  this.pageSize$,
  this.sortColumn$,
  this.sortDirection$,
  this.filterQuery$.pipe(
    debounceTime(300), // Debounce filter input
    distinctUntilChanged()
  )
]).pipe(
  // Map the array of values to a parameter object
  map(([page, pageSize, sortColumn, sortDirection, filter]) => ({
    page,
    pageSize,
    sortColumn,
    sortDirection,
    filter
  }))
);
```

## 3. Triggering the API Call

Finally, we pipe the `params$` stream into a `switchMap` to make the API call. `switchMap` is perfect here because if any parameter changes (e.g., the user goes to the next page or applies a filter), it will automatically cancel the previous request and start a new one with the updated parameters.

The result is a single `data$` observable that represents the final, observable list of data and its pagination metadata.

```typescript
// products.service.ts (continued)
import { switchMap } from 'rxjs/operators';

export interface PaginatedProducts {
  items: Product[];
  totalCount: number;
  page: number;
  pageSize: number;
}

// The final data stream
data$: Observable<PaginatedProducts> = this.params$.pipe(
  // Use switchMap to cancel previous requests and make a new one
  switchMap(params => this.fetchProducts(params))
);

private fetchProducts(params: ProductRequestParams): Observable<PaginatedProducts> {
  // Construct HttpParams from the params object
  let httpParams = new HttpParams()
    .set('_page', params.page.toString())
    .set('_limit', params.pageSize.toString())
    .set('_sort', params.sortColumn)
    .set('_order', params.sortDirection);

  if (params.filter) {
    httpParams = httpParams.set('q', params.filter);
  }

  // In a real API, the total count would often come from a header
  // like 'X-Total-Count'. We'll simulate it here.
  return this.httpClient.get<Product[]>(this.apiUrl, { params, observe: 'response' }).pipe(
    map(response => ({
      items: response.body || [],
      totalCount: parseInt(response.headers.get('X-Total-Count') || '0', 10),
      page: params.page,
      pageSize: params.pageSize
    }))
  );
}
```

## 4. Connecting to the UI

Your component can now subscribe to the `data$` observable. The UI (e.g., a table, paginator component, and filter input) simply calls the public action methods (`changePage`, `applyFilter`, etc.) on the service. The reactive stream handles the rest.

```typescript
// products-list.component.ts
@Component({ /* ... */ })
export class ProductsListComponent {
  // Inject the service
  constructor(public productsService: ProductsService) {}

  // The template can directly subscribe to the data$ observable
  // using the async pipe.
  data$ = this.productsService.data$;

  // UI event handlers just call the service methods
  onPageChange(page: number) {
    this.productsService.changePage(page);
  }

  onSort(column: string) {
    this.productsService.changeSort(column);
  }

  onFilter(event: Event) {
    const query = (event.target as HTMLInputElement).value;
    this.productsService.applyFilter(query);
  }
}
```

This pattern creates a clean separation of concerns. The UI is responsible for dispatching user intent, and the service is responsible for managing the state and orchestrating the data fetching logic in a predictable, reactive, and efficient way. This approach works seamlessly with component libraries like Angular Material's Paginator and Sort Header.