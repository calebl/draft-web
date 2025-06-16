import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'

export default class extends Controller {
  connect() {
    this.sortable = Sortable.create(this.element, {
      group: 'shared',
      handle: '.handle',
      animation: 150,
      onEnd: this.end.bind(this)
    })
  }

  end(event) {
    let id = event.item.dataset.id || event.item.firstElementChild.dataset.id
    let data = new FormData()
    data.append('outline_item[position]', event.newIndex + 1)

    let url = event.target.dataset.url

    fetch(url.replace(':id', id), {
      method: 'PATCH',
      body: data,
      headers: {
        'Accept': 'text/vnd.turbo-stream.html'
      }
    })
  }
}