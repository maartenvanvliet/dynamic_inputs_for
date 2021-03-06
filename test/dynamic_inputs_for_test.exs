defmodule DynamicInputsForTest do
  use ExUnit.Case

  import Phoenix.HTML
  import Phoenix.HTML.Form
  import DynamicInputsFor
  doctest DynamicInputsFor

  defmodule Product do
    defstruct [:name]
  end

  defp conn(params \\ %{}) do
    Plug.Test.conn(:get, "/forms", params)
  end

  defp dynamic_form(conn, opts \\ []) do
    opts = Keyword.put_new(opts, :default, [])

    form_for(conn, "/", [as: :shop], fn form ->
      dynamic_inputs_for(form, :products, %Product{}, opts, fn f_product ->
        text_input(f_product, :name)
      end)
    end)
    |> safe_to_string()
  end

  defp params_deleted_products do
    %{
      "shop" => %{
        "products" => %{
          "0" => %{
            "name" => "wer",
            "delete" => "true"
          }
        }
      }
    }
  end

  describe "dynamic_inputs_for/5" do
    test "generate an HTML element with the template and information for the new fields" do
      assert dynamic_form(conn()) =~ ~s(data-assoc=\"products\")
      assert dynamic_form(conn()) =~ ~s(data-assoc-id=\"shop_products_0\")
      assert dynamic_form(conn()) =~ ~s(data-assoc-name=\"shop[products][0]\")
      assert dynamic_form(conn()) =~ ~s(data-assoc-only-mark-deleted=\"false\")
      assert dynamic_form(conn()) =~ ~s(id=\"dynamic_info_products\")
      assert dynamic_form(conn()) =~ ~s(style=\"display: none;\")

      assert dynamic_form(conn()) =~
               ~s(data-assoc-template=\"&lt;div class=&quot;fields&quot; data-assoc=&quot;products&quot;&gt;&lt;input id=&quot;shop_products_0_name&quot; name=&quot;shop[products][0][name]&quot; type=&quot;text&quot;&gt;&lt;/div&gt;\")
    end

    test "wrap nested fields in the class \"fields\"" do
      assert dynamic_form(conn(), default: [%Product{name: "asdf"}]) =~
               ~s(<div class=\"fields\" data-assoc=\"products\" data-assoc-index=\"0\"><input id=\"shop_products_0_name\" name=\"shop[products][0][name]\" type=\"text\" value=\"asdf\"></div>)
    end

    test "wrap in the given HTML tag" do
      assert dynamic_form(conn(), default: [%Product{name: "asdf"}], wrapper_tag: :span) =~
               ~s(<span class=\"fields\" data-assoc=\"products\" data-assoc-index=\"0\"><input id=\"shop_products_0_name\")

      assert dynamic_form(conn(), default: [%Product{name: "asdf"}], wrapper_tag: :span) =~
               ~s(<span data-assoc=\"products\" data-assoc-id=\"shop_products_0\")
    end

    test "add the attributes given in the wrapper" do
      assert dynamic_form(conn(),
               default: [%Product{name: "asdf"}],
               wrapper_attrs: [class: "fake-class"]
             ) =~
               ~s(<div class=\"fields fake-class\" data-assoc=\"products\" data-assoc-index=\"0\"><input id=\"shop_products_0_name\")
    end

    test "if fields are marked for deletion only render input \"delete\"" do
      conn = conn(params_deleted_products())

      assert dynamic_form(conn) =~
               ~s(<div class=\"fields deleted-fields\" data-assoc=\"products\" data-assoc-index=\"0\" style=\"display: none;\"><input id=\"shop_products_0_delete\" name=\"shop[products][0][delete]\" type=\"hidden\" value=\"true\">)
    end

    test "if fields are marked for deletion, \"only_mark_deleted\" option render everything" do
      conn = conn(params_deleted_products())

      assert dynamic_form(conn, only_mark_deleted: true) =~
               ~s(<div class=\"fields deleted-fields\" data-assoc=\"products\" data-assoc-index=\"0\"><input id=\"shop_products_0_name\" name=\"shop[products][0][name]\" type=\"text\" value=\"wer\">)
    end
  end

  test "dynamic_add_button" do
    assert dynamic_add_button(:products, "Add") |> safe_to_string() ==
             "<button data-assoc=\"products\" data-assoc-add=\"\" type=\"button\">Add</button>"

    assert dynamic_add_button(:products, [class: "button"], do: "Add") |> safe_to_string() ==
             "<button class=\"button\" data-assoc=\"products\" data-assoc-add=\"\" type=\"button\">Add</button>"

    assert dynamic_add_button(:products, "Add", class: "button") |> safe_to_string() ==
             "<button class=\"button\" data-assoc=\"products\" data-assoc-add=\"\" type=\"button\">Add</button>"
  end

  test "dynamic_delete_button" do
    assert dynamic_delete_button("Remove") |> safe_to_string() ==
             "<button data-assoc-delete=\"\" type=\"button\">Remove</button>"

    assert dynamic_delete_button([class: "button"], do: "Remove") |> safe_to_string() ==
             "<button class=\"button\" data-assoc-delete=\"\" type=\"button\">Remove</button>"

    assert dynamic_delete_button("Remove", class: "button") |> safe_to_string() ==
             "<button class=\"button\" data-assoc-delete=\"\" type=\"button\">Remove</button>"
  end
end
