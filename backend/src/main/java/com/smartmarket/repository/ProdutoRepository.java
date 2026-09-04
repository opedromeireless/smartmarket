package com.smartmarket.repository;

import com.smartmarket.model.Produto;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ProdutoRepository extends JpaRepository<Produto, Long> {
    List<Produto> findByCategoria(String categoria);
    List<Produto> findByNomeNormalizadoContaining(String texto);
}
