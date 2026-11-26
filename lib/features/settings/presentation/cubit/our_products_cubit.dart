import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tuhfatul_muslim/features/settings/domain/entities/product_item.dart';
import 'package:tuhfatul_muslim/features/settings/domain/usecases/get_our_products.dart';

enum OurProductsStatus { loading, success, failure }

class OurProductsState {
  const OurProductsState({
    this.status = OurProductsStatus.loading,
    this.products = const [],
    this.errorMessage,
  });

  final OurProductsStatus status;
  final List<ProductItem> products;
  final String? errorMessage;
}

/// Loads the Our Products list for its screen.
class OurProductsCubit extends Cubit<OurProductsState> {
  OurProductsCubit(this._getOurProducts) : super(const OurProductsState());

  final GetOurProducts _getOurProducts;

  Future<void> load() async {
    emit(const OurProductsState());
    final result = await _getOurProducts();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => OurProductsState(
          status: OurProductsStatus.failure,
          errorMessage: failure.message,
        ),
        (products) => OurProductsState(
          status: OurProductsStatus.success,
          // An unpublished product is not meant to be shown yet.
          products: products.where((p) => p.isPublished).toList(),
        ),
      ),
    );
  }
}
